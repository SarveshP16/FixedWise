import 'package:flutter/material.dart';

/// The dark, ink-filled button (`.btn.primary`) — used for a secondary
/// action inside a row of two buttons (e.g. Detail's "Download
/// certificate"). For the single big brass call-to-action at the bottom of
/// a form, use `CtaButton` instead.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(onPressed: onPressed, child: Text(label));
  }
}
