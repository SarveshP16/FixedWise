import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_colors.dart';
import 'app_lock_controller.dart';
import 'pin_create_screen.dart';
import 'pin_service.dart';
import 'widgets/pin_entry_view.dart';

/// The full-screen PIN prompt shown, opaquely, over the rest of the app
/// while [AppLockState.isLocked] is true. Layered on top of the routed
/// content in a `Stack` (see `app.dart`'s `MaterialApp.builder`) rather
/// than replacing it outright — swapping the whole subtree out while
/// locked would unmount go_router's own `Navigator`, silently resetting
/// you to the dashboard on every unlock instead of wherever you actually
/// were.
class AppLockGate extends ConsumerStatefulWidget {
  const AppLockGate({super.key});

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate> {
  String? _error;
  int _attempt = 0;
  bool _biometricBusy = false;
  bool _autoPrompted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Auto-attempt biometric once per time the gate appears, so a
    // biometric-enabled user usually never has to touch the keypad at
    // all — but only once, so declining it doesn't re-prompt on every
    // rebuild while they're typing a PIN instead.
    if (!_autoPrompted && ref.read(appLockProvider).biometricEnabled) {
      _autoPrompted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometric());
    }
  }

  Future<void> _tryBiometric() async {
    if (_biometricBusy || !mounted) return;
    setState(() => _biometricBusy = true);
    final service = ref.read(deviceAuthServiceProvider);
    final available = await service.isAvailable();
    if (!available) {
      if (mounted) setState(() => _biometricBusy = false);
      return;
    }
    final ok = await service.authenticate(reason: 'Unlock FixedWise');
    if (!mounted) return;
    setState(() => _biometricBusy = false);
    if (ok) ref.read(appLockProvider.notifier).unlock();
  }

  Future<void> _handlePinComplete(String pin) async {
    final ok = await ref.read(pinServiceProvider).verify(pin);
    if (!mounted) return;
    if (ok) {
      ref.read(appLockProvider.notifier).unlock();
    } else {
      final lockout = await ref.read(pinServiceProvider).lockoutRemaining();
      if (!mounted) return;
      setState(() {
        _error = pinRejectedMessage(lockout);
        _attempt++;
      });
    }
  }

  Future<void> _forgotPin() async {
    setState(() => _biometricBusy = true);
    final service = ref.read(deviceAuthServiceProvider);
    final available = await service.isAvailable();
    if (!available) {
      if (!mounted) return;
      setState(() {
        _biometricBusy = false;
        _error = "Your device doesn't have a lock screen set up to reset with";
      });
      return;
    }
    final ok = await service.authenticate(reason: "Verify it's you to reset your FixedWise PIN");
    if (!mounted) return;
    setState(() => _biometricBusy = false);
    if (!ok) return;

    final created = await showPinCreateFlow(context, title: 'Set a new PIN');
    if (created) ref.read(appLockProvider.notifier).unlock();
  }

  @override
  Widget build(BuildContext context) {
    final biometricEnabled = ref.watch(appLockProvider).biometricEnabled;

    return Material(
      color: AppColors.paper,
      child: SafeArea(
        child: Center(
          child: PinEntryView(
            key: ValueKey(_attempt),
            title: 'Enter your PIN',
            subtitle: 'FixedWise is locked',
            errorText: _error,
            onComplete: _handlePinComplete,
            onBiometric: biometricEnabled ? _tryBiometric : null,
            footer: TextButton(onPressed: _biometricBusy ? null : _forgotPin, child: const Text('Forgot PIN?')),
          ),
        ),
      ),
    );
  }
}
