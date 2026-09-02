import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/currency_formatter.dart' show settingsRepositoryProvider;
import 'device_auth_service.dart';
import 'pin_service.dart';

final pinServiceProvider = Provider<PinService>((ref) => PinService());

final deviceAuthServiceProvider = Provider<DeviceAuthService>((ref) => DeviceAuthService());

/// Whether this device has *any* biometric/lock-screen credential set up
/// at all — Profile only offers the "Use biometric unlock" toggle when
/// this is true, since there'd be nothing for it to actually use
/// otherwise.
final deviceAuthAvailableProvider = FutureProvider<bool>((ref) {
  return ref.watch(deviceAuthServiceProvider).isAvailable();
});

@immutable
class AppLockState {
  const AppLockState({required this.pinConfigured, required this.biometricEnabled, required this.isUnlocked});

  /// Whether a PIN has been set up at all — if not, the app never locks
  /// (the whole feature is optional, off by default).
  final bool pinConfigured;

  /// Whether the lock screen should also offer a biometric/device-
  /// credential quick-unlock alongside PIN entry. Meaningless while
  /// [pinConfigured] is false.
  final bool biometricEnabled;

  /// Whether the app has been unlocked this "session" (resets when the
  /// app is backgrounded — see [FixedWiseApp]'s lifecycle observer, not on
  /// every rebuild).
  final bool isUnlocked;

  bool get isLocked => pinConfigured && !isUnlocked;

  AppLockState copyWith({bool? pinConfigured, bool? biometricEnabled, bool? isUnlocked}) {
    return AppLockState(
      pinConfigured: pinConfigured ?? this.pinConfigured,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      isUnlocked: isUnlocked ?? this.isUnlocked,
    );
  }
}

/// Whether the whole app is currently locked behind a PIN. Profile's
/// Security section calls [refresh] after touching [PinService]/settings
/// directly, so this state stays in sync without owning the storage
/// itself.
class AppLockController extends Notifier<AppLockState> {
  @override
  AppLockState build() {
    _restore();
    return const AppLockState(pinConfigured: false, biometricEnabled: false, isUnlocked: false);
  }

  Future<void> _restore() async {
    final configured = await ref.read(pinServiceProvider).isSet();
    final biometric = ref.read(settingsRepositoryProvider).getBiometricUnlockEnabled();
    state = state.copyWith(pinConfigured: configured, biometricEnabled: biometric);
  }

  Future<void> refresh() => _restore();

  Future<void> setBiometricEnabled(bool value) async {
    state = state.copyWith(biometricEnabled: value);
    await ref.read(settingsRepositoryProvider).setBiometricUnlockEnabled(value);
  }

  void unlock() => state = state.copyWith(isUnlocked: true);

  void lock() => state = state.copyWith(isUnlocked: false);
}

final appLockProvider = NotifierProvider<AppLockController, AppLockState>(AppLockController.new);
