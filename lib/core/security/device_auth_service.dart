import 'package:local_auth/local_auth.dart';

/// The minimal device-credential operations [DeviceAuthService] needs —
/// abstracted so tests can swap in a fake instead of the real `local_auth`
/// plugin. This matters more than it might seem: `local_auth` is federated,
/// and on a Windows dev machine `flutter test` picks up its Windows
/// implementation, which makes a genuine native call that just hangs
/// forever in a widget test (no engine to route it through) rather than
/// throwing like a missing platform channel normally would.
abstract class DeviceAuthenticator {
  Future<bool> isAvailable();

  Future<bool> authenticate({required String reason});
}

class LocalAuthDeviceAuthenticator implements DeviceAuthenticator {
  final _auth = LocalAuthentication();

  @override
  Future<bool> isAvailable() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> authenticate({required String reason}) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        // Explicitly false: any device credential (PIN/pattern/password),
        // not just biometrics, should be able to unlock or reset a
        // forgotten app-lock PIN.
        biometricOnly: false,
      );
    } catch (_) {
      return false;
    }
  }
}

/// Wraps the device's own lock-screen credential (fingerprint/face/PIN/
/// pattern) — used both as a quick-unlock option on the app lock screen
/// (when the user's turned "Use biometric unlock" on) and for the "forgot
/// your PIN" reset path.
class DeviceAuthService {
  DeviceAuthService({DeviceAuthenticator? authenticator}) : _authenticator = authenticator ?? LocalAuthDeviceAuthenticator();

  final DeviceAuthenticator _authenticator;

  /// Whether the device has *any* lock-screen security set up at all
  /// (biometric enrolled, or a device PIN/pattern/password). If this is
  /// false, there's nothing to fall back to, and "Use biometric unlock"
  /// shouldn't even be offered as a setting.
  Future<bool> isAvailable() => _authenticator.isAvailable();

  /// Prompts the device's own lock-screen credential check. Returns true
  /// only on a genuine success — any error (cancelled, no hardware, too
  /// many attempts, etc.) is treated as "not authenticated" rather than
  /// thrown, since callers only ever care about pass/fail here.
  Future<bool> authenticate({required String reason}) => _authenticator.authenticate(reason: reason);
}
