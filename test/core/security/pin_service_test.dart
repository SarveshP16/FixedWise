import 'package:fixedwise_app/core/security/pin_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// An in-memory [SecureKeyValueStore] — real widget tests have no platform
/// Keystore/secure-storage backend at all, so [PinService] is built
/// against this abstraction specifically to stay testable without one.
class _FakeSecureKeyValueStore implements SecureKeyValueStore {
  final _values = <String, String>{};

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async => _values[key] = value;

  @override
  Future<void> delete(String key) async => _values.remove(key);
}

void main() {
  late PinService pinService;

  setUp(() {
    pinService = PinService(store: _FakeSecureKeyValueStore());
  });

  test('isSet is false until a PIN is stored', () async {
    expect(await pinService.isSet(), isFalse);
    await pinService.setPin('123456');
    expect(await pinService.isSet(), isTrue);
  });

  test('verify accepts the correct PIN and rejects everything else', () async {
    await pinService.setPin('482913');
    expect(await pinService.verify('482913'), isTrue);
    expect(await pinService.verify('000000'), isFalse);
  });

  test('the raw PIN is never stored — only its hash', () async {
    final store = _FakeSecureKeyValueStore();
    final service = PinService(store: store);
    await service.setPin('123456');
    final stored = await store.read('fixedwise.appLock.pinHash');
    expect(stored, isNotNull);
    expect(stored, isNot('123456'));
  });

  test('clear removes the PIN entirely', () async {
    await pinService.setPin('123456');
    await pinService.clear();
    expect(await pinService.isSet(), isFalse);
    expect(await pinService.verify('123456'), isFalse);
  });

  test('verify against no stored PIN is false, not an error', () async {
    expect(await pinService.verify('123456'), isFalse);
  });

  test('the stored hash is salted — the same PIN never hashes the same way twice', () async {
    final storeA = _FakeSecureKeyValueStore();
    final storeB = _FakeSecureKeyValueStore();
    await PinService(store: storeA).setPin('123456');
    await PinService(store: storeB).setPin('123456');
    final a = await storeA.read('fixedwise.appLock.pinHash');
    final b = await storeB.read('fixedwise.appLock.pinHash');
    expect(a, startsWith('pbkdf2\$'));
    expect(a, isNot(b));
  });

  test('a PIN saved by an older version (plain SHA-256) still unlocks, then gets upgraded', () async {
    final store = _FakeSecureKeyValueStore();
    // sha256('123456')
    await store.write('fixedwise.appLock.pinHash', '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92');
    final service = PinService(store: store);
    expect(await service.verify('123456'), isTrue);
    expect(await store.read('fixedwise.appLock.pinHash'), startsWith('pbkdf2\$'));
    expect(await service.verify('123456'), isTrue);
  });

  test('locks out after repeated wrong guesses, then lets the right PIN in once it expires', () async {
    var now = DateTime(2026, 1, 1, 12);
    final service = PinService(store: _FakeSecureKeyValueStore(), clock: () => now);
    await service.setPin('482913');

    for (var i = 0; i < PinService.freeAttempts; i++) {
      expect(await service.verify('000000'), isFalse);
    }
    expect(await service.lockoutRemaining(), const Duration(seconds: 30));
    // Even the right PIN is refused while locked out.
    expect(await service.verify('482913'), isFalse);

    now = now.add(const Duration(seconds: 31));
    expect(await service.lockoutRemaining(), Duration.zero);
    expect(await service.verify('482913'), isTrue);

    // A success resets the counter — one more miss doesn't lock again.
    expect(await service.verify('000000'), isFalse);
    expect(await service.lockoutRemaining(), Duration.zero);
  });

  test('each further miss doubles the lockout', () async {
    var now = DateTime(2026, 1, 1, 12);
    final service = PinService(store: _FakeSecureKeyValueStore(), clock: () => now);
    await service.setPin('482913');
    for (var i = 0; i < PinService.freeAttempts; i++) {
      await service.verify('000000');
    }
    now = now.add(const Duration(seconds: 31));
    await service.verify('000000');
    expect(await service.lockoutRemaining(), const Duration(minutes: 1));
  });
}
