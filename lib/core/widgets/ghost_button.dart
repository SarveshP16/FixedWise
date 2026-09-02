import 'package:flutter/material.dart';

/// The outlined, transparent button (`.btn.ghost`) — used for a
/// lower-emphasis action alongside a `PrimaryButton` (e.g. Detail's
/// "Close early").
class GhostButton extends StatelessWidget {
  const GhostButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(onPressed: onPressed, child: Text(label));
  }
}
