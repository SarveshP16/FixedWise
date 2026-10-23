import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_colors.dart';
import 'app_lock_controller.dart';
import 'pin_service.dart';
import 'widgets/pin_entry_view.dart';

/// Confirms you know the current PIN (used before changing or removing
/// one in Profile) — with a device-lock fallback in case you don't.
/// Returns true once verified, false if backed out.
Future<bool> showPinVerifyFlow(BuildContext context, {String title = 'Enter your PIN'}) async {
  final result = await Navigator.of(
    context,
  ).push<bool>(MaterialPageRoute(builder: (context) => _PinVerifyScreen(title: title)));
  return result ?? false;
}

class _PinVerifyScreen extends ConsumerStatefulWidget {
  const _PinVerifyScreen({required this.title});

  final String title;

  @override
  ConsumerState<_PinVerifyScreen> createState() => _PinVerifyScreenState();
}

class _PinVerifyScreenState extends ConsumerState<_PinVerifyScreen> {
  String? _error;
  int _attempt = 0;
  bool _busy = false;

  Future<void> _handleComplete(String pin) async {
    final ok = await ref.read(pinServiceProvider).verify(pin);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      final lockout = await ref.read(pinServiceProvider).lockoutRemaining();
      if (!mounted) return;
      setState(() {
        _error = pinRejectedMessage(lockout);
        _attempt++;
      });
    }
  }

  Future<void> _useDeviceAuth() async {
    setState(() => _busy = true);
    final service = ref.read(deviceAuthServiceProvider);
    final available = await service.isAvailable();
    if (!available) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = "Your device doesn't have a lock screen set up";
      });
      return;
    }
    final ok = await service.authenticate(reason: "Verify it's you to continue");
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        backgroundColor: AppColors.paper,
        elevation: 0,
        title: Text(widget.title),
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop(false)),
      ),
      body: SafeArea(
        child: Center(
          child: PinEntryView(
            key: ValueKey(_attempt),
            title: 'Enter your PIN',
            errorText: _error,
            onComplete: (pin) => _handleComplete(pin),
            footer: TextButton(onPressed: _busy ? null : _useDeviceAuth, child: const Text('Use device unlock instead')),
          ),
        ),
      ),
    );
  }
}
