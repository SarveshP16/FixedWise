import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// A small rounded-square avatar showing one initial letter (`.chip`) —
/// used for a bank's initial on a deposit row, or a holder's initial
/// elsewhere.
class InitialChip extends StatelessWidget {
  const InitialChip({super.key, required this.label, this.size = 34});

  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: AppColors.brassTint, borderRadius: BorderRadius.circular(10)),
      child: Text(
        label.isEmpty ? '?' : label.characters.first.toUpperCase(),
        style: AppTypography.chipInitial,
      ),
    );
  }
}
