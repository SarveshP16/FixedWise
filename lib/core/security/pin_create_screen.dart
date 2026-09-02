import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_colors.dart';
import 'app_lock_controller.dart';
import 'widgets/pin_entry_view.dart';

/// Two-step "enter a PIN, then confirm it" flow, used for initial setup,
/// the second half of changing a PIN, and after a successful "forgot PIN"
/// device-auth reset. Returns true once a new PIN is saved, false if the
/// user backs out.
Future<bool> showPinCreateFlow(BuildContext context, {String title = 'Set a PIN'}) async {
  final result = await Navigator.of(
    context,
  ).push<bool>(MaterialPageRoute(builder: (context) => _PinCreateScreen(title: title)));
  return result ?? false;
}

enum _Step { enter, confirm }

class _PinCreateScreen extends ConsumerStatefulWidget {
  const _PinCreateScreen({required this.title});

  final String title;

  @override
  ConsumerState<_PinCreateScreen> createState() => _PinCreateScreenState();
}

class _PinCreateScreenState extends ConsumerState<_PinCreateScreen> {
  _Step _step = _Step.enter;
  String? _firstEntry;
  String? _error;
  int _attempt = 0;

  Future<void> _handleComplete(String pin) async {
    if (_step == _Step.enter) {
      setState(() {
        _firstEntry = pin;
        _step = _Step.confirm;
        _error = null;
        _attempt++;
      });
      return;
    }

    if (pin == _firstEntry) {
      await ref.read(pinServiceProvider).setPin(pin);
      await ref.read(appLockProvider.notifier).refresh();
      if (mounted) Navigator.of(context).pop(true);
    } else {
      setState(() {
        _error = "PINs didn't match — start over";
        _step = _Step.enter;
        _firstEntry = null;
        _attempt++;
      });
    }
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
            title: _step == _Step.enter ? 'Enter a 6-digit PIN' : 'Confirm your PIN',
            errorText: _error,
            onComplete: (pin) => _handleComplete(pin),
          ),
        ),
      ),
    );
  }
}
