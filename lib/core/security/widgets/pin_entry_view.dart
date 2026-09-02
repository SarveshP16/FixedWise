import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import 'numeric_keypad.dart';
import 'pin_dots.dart';

/// Title + dots + numeric keypad, reused for every PIN step (unlock,
/// create, confirm). Calls [onComplete] once [digitCount] digits are
/// entered — the caller decides what happens next (verify it, ask for
/// confirmation, show an error). To reset the entered digits after a
/// failed attempt, remount this widget with a new `key` (e.g. bump a
/// counter) rather than reaching into its state.
class PinEntryView extends StatefulWidget {
  const PinEntryView({
    super.key,
    required this.title,
    this.subtitle,
    required this.onComplete,
    this.errorText,
    this.footer,
    this.onBiometric,
    this.digitCount = 6,
  });

  final String title;
  final String? subtitle;
  final ValueChanged<String> onComplete;
  final String? errorText;
  final Widget? footer;

  /// Shown as a fourth keypad key (fingerprint icon) when provided —
  /// omit to leave that corner as a plain empty spacer.
  final VoidCallback? onBiometric;
  final int digitCount;

  @override
  State<PinEntryView> createState() => _PinEntryViewState();
}

class _PinEntryViewState extends State<PinEntryView> {
  String _entered = '';

  void _onDigit(String digit) {
    if (_entered.length >= widget.digitCount) return;
    setState(() => _entered += digit);
    if (_entered.length == widget.digitCount) {
      widget.onComplete(_entered);
    }
  }

  void _onBackspace() {
    if (_entered.isEmpty) return;
    setState(() => _entered = _entered.substring(0, _entered.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.title, textAlign: TextAlign.center, style: AppTypography.screenTitle),
        if (widget.subtitle != null) ...[
          const SizedBox(height: 8),
          Text(widget.subtitle!, textAlign: TextAlign.center, style: AppTypography.dateLine),
        ],
        const SizedBox(height: 28),
        PinDots(digitCount: widget.digitCount, enteredLength: _entered.length),
        SizedBox(
          height: 32,
          child: widget.errorText == null
              ? null
              : Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    widget.errorText!,
                    style: AppTypography.dateLine.copyWith(color: AppColors.error),
                  ),
                ),
        ),
        const SizedBox(height: 12),
        NumericKeypad(onDigit: _onDigit, onBackspace: _onBackspace, onBiometric: widget.onBiometric),
        if (widget.footer != null) ...[
          const SizedBox(height: 12),
          widget.footer!,
        ],
      ],
    );
  }
}
