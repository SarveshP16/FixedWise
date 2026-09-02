import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// A form field's caption label plus whatever control sits under it
/// (`.field`) — the control itself (a text field, a picker row, a slider,
/// a segmented control) is passed in as [child] so this only standardizes
/// the label and vertical spacing every field shares.
class FixedwiseFieldShell extends StatelessWidget {
  const FixedwiseFieldShell({super.key, required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(label, style: AppTypography.fieldLabel)),
          child,
        ],
      ),
    );
  }
}

/// The bordered, rounded input box a field's control sits inside (`.field
/// .input`) — used for a plain text field or a tappable picker row (bank
/// name, holder). Not used by the tenure slider or segmented controls,
/// which already carry their own container.
class FixedwiseInputBox extends StatelessWidget {
  const FixedwiseInputBox({super.key, required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final box = Container(
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 13),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Expanded(child: child)]),
    );
    if (onTap == null) return box;
    return InkWell(borderRadius: BorderRadius.circular(12), onTap: onTap, child: box);
  }
}
