import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _pinHashKey = 'fixedwise.appLock.pinHash';
const _failedAttemptsKey = 'fixedwise.appLock.failedAttempts';
const _lockedUntilKey = 'fixedwise.appLock.lockedUntil';

/// The minimal secure key-value operations [PinService] needs — abstracted
/// so tests can swap in an in-memory fake instead of needing a real
/// platform Keystore (widget tests have no secure-storage backend at all).
abstract class SecureKeyValueStore {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);
}

class FlutterSecureKeyValueStore implements SecureKeyValueStore {
  final _storage = const FlutterSecureStorage();

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) => _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

/// Stores the app-lock PIN as a salted PBKDF2-HMAC-SHA256 hash in the
/// platform's secure storage (Android Keystore-backed), never the raw
/// digits. A short numeric PIN can't be made brute-force-proof by hashing
/// alone, so the real protections are the Keystore encryption around the
/// hash plus [lockoutRemaining]'s escalating lockout on wrong guesses; the
/// salt and stretching just make an extracted hash useless to a
/// precomputed table and slow to grind through.
class PinService {
  PinService({SecureKeyValueStore? store, DateTime Function()? clock})
    : _store = store ?? FlutterSecureKeyValueStore(),
      _clock = clock ?? DateTime.now;

  final SecureKeyValueStore _store;
  final DateTime Function() _clock;

  static const _iterations = 20000;

  /// Wrong guesses allowed before the first lockout kicks in.
  static const freeAttempts = 5;

  static const _firstLockout = Duration(seconds: 30);
  static const _maxLockout = Duration(hours: 1);

  /// Read failures (secure storage unavailable — a corrupted keystore,
  /// etc.) are treated as "no PIN set" rather than left to throw as an
  /// unhandled Future rejection: this runs from [AppLockController.build],
  /// where an exception would otherwise surface nowhere useful. Failing
  /// safe here still leaves the app reachable (unlocked) rather than stuck
  /// behind a lock screen with no way to enter a PIN that was never
  /// actually readable to begin with.
  Future<bool> isSet() async {
    try {
      final hash = await _store.read(_pinHashKey);
      return hash != null;
    } catch (_) {
      return false;
    }
  }

  Future<void> setPin(String pin) async {
    await _store.write(_pinHashKey, _hash(pin, _newSalt(), _iterations));
    await _resetFailures();
  }

  /// `false` for a wrong PIN, and also — without checking the PIN at all —
  /// while a lockout is running; callers ask [lockoutRemaining] to tell
  /// the two apart.
  Future<bool> verify(String pin) async {
    try {
      if (await lockoutRemaining() > Duration.zero) return false;
      final stored = await _store.read(_pinHashKey);
      if (stored == null) return false;

      final ok = _matches(pin, stored);
      if (ok) {
        await _resetFailures();
        // Upgrades a PIN saved by an older version (unsalted SHA-256) the
        // first time it's entered correctly.
        if (!stored.startsWith('pbkdf2\$')) await setPin(pin);
      } else {
        await _recordFailure();
      }
      return ok;
    } catch (_) {
      return false;
    }
  }

  /// How long PIN entry stays blocked after too many wrong guesses —
  /// [Duration.zero] when it isn't. Kept in secure storage so killing and
  /// relaunching the app doesn't reset it.
  Future<Duration> lockoutRemaining() async {
    final raw = await _store.read(_lockedUntilKey);
    final lockedUntil = raw == null ? null : DateTime.tryParse(raw);
    if (lockedUntil == null) return Duration.zero;
    final remaining = lockedUntil.difference(_clock());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  Future<void> clear() async {
    await _store.delete(_pinHashKey);
    await _resetFailures();
  }

  Future<void> _recordFailure() async {
    final failures = int.tryParse(await _store.read(_failedAttemptsKey) ?? '') ?? 0;
    final next = failures + 1;
    await _store.write(_failedAttemptsKey, '$next');
    if (next < freeAttempts) return;

    // 30s, 1m, 2m, 4m… capped at an hour.
    final doublings = min(next - freeAttempts, 7);
    var lockout = _firstLockout * pow(2, doublings).toInt();
    if (lockout > _maxLockout) lockout = _maxLockout;
    await _store.write(_lockedUntilKey, _clock().add(lockout).toIso8601String());
  }

  Future<void> _resetFailures() async {
    await _store.delete(_failedAttemptsKey);
    await _store.delete(_lockedUntilKey);
  }

  static bool _matches(String pin, String stored) {
    if (!stored.startsWith('pbkdf2\$')) {
      return _constantTimeEquals(sha256.convert(utf8.encode(pin)).toString(), stored);
    }
    final parts = stored.split('\$');
    if (parts.length != 4) return false;
    final iterations = int.tryParse(parts[1]);
    if (iterations == null) return false;
    return _constantTimeEquals(_hash(pin, base64.decode(parts[2]), iterations), stored);
  }

  static List<int> _newSalt() {
    final random = Random.secure();
    return List<int>.generate(16, (_) => random.nextInt(256));
  }

  static String _hash(String pin, List<int> salt, int iterations) {
    final derived = _pbkdf2(utf8.encode(pin), salt, iterations);
    return 'pbkdf2\$$iterations\$${base64.encode(salt)}\$${base64.encode(derived)}';
  }

  /// PBKDF2-HMAC-SHA256 with a single 32-byte output block — `package:
  /// crypto` has HMAC but no PBKDF2, and one block is all a PIN hash needs.
  static List<int> _pbkdf2(List<int> password, List<int> salt, int iterations) {
    final hmac = Hmac(sha256, password);
    var block = hmac.convert([...salt, 0, 0, 0, 1]).bytes;
    final result = List<int>.of(block);
    for (var i = 1; i < iterations; i++) {
      block = hmac.convert(block).bytes;
      for (var j = 0; j < result.length; j++) {
        result[j] ^= block[j];
      }
    }
    return result;
  }

  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}

/// The lock screens' error line after a rejected PIN: either a plain
/// "Incorrect PIN", or how long until the next guess is allowed.
String pinRejectedMessage(Duration lockout) {
  if (lockout <= Duration.zero) return 'Incorrect PIN';
  final seconds = lockout.inSeconds + 1;
  final wait = seconds < 60 ? '$seconds s' : '${(seconds / 60).ceil()} min';
  return 'Too many attempts — try again in $wait';
}
