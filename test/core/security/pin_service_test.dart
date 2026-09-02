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
}
