import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _pinHashKey = 'fixedwise.appLock.pinHash';

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

/// Stores the app-lock PIN as a hashed value in the platform's secure
/// storage (Android Keystore-backed), never the raw digits — defense in
/// depth on top of secure storage already being encrypted at rest.
class PinService {
  PinService({SecureKeyValueStore? store}) : _store = store ?? FlutterSecureKeyValueStore();

  final SecureKeyValueStore _store;

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
    await _store.write(_pinHashKey, _hash(pin));
  }

  Future<bool> verify(String pin) async {
    try {
      final stored = await _store.read(_pinHashKey);
      if (stored == null) return false;
      return stored == _hash(pin);
    } catch (_) {
      return false;
    }
  }

  Future<void> clear() async {
    await _store.delete(_pinHashKey);
  }

  String _hash(String pin) => sha256.convert(utf8.encode(pin)).toString();
}
