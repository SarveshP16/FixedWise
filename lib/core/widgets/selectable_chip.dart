import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// A rounded filter chip — filled dark when selected, outlined when not.
/// Shared by every horizontally-scrolling filter row (holder, deposit
/// status, …) so they all read as the same "this is a filter" affordance
/// rather than each screen inventing its own look.
class SelectableChip extends StatelessWidget {
  const SelectableChip({super.key, required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.ink : AppColors.card,
          border: Border.all(color: selected ? AppColors.ink : AppColors.line),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppTypography.pillLabel.copyWith(color: selected ? AppColors.heroOnDark : AppColors.text),
        ),
      ),
    );
  }
}
