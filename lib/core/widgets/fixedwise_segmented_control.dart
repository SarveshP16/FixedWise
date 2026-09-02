import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// The mockup's segmented control (`.seg`/`.seg div.sel`) — a row of
/// equal-width options in a bordered pill, the selected one filled dark.
/// Has no direct Material equivalent (`SegmentedButton` looks quite
/// different), so this is a small custom widget reused by every
/// Compounding/Payout-type choice in the app.
class FixedwiseSegmentedControl<T> extends StatelessWidget {
  const FixedwiseSegmentedControl({
    super.key,
    required this.options,
    required this.labelBuilder,
    required this.value,
    required this.onChanged,
  });

  final List<T> options;
  final String Function(T) labelBuilder;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          for (final option in options)
            Expanded(
              child: _Segment(
                label: labelBuilder(option),
                selected: option == value,
                onTap: () => onChanged(option),
              ),
            ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: selected ? AppColors.ink : Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
        alignment: Alignment.center,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: selected ? AppTypography.segmentLabelSelected : AppTypography.segmentLabel,
        ),
      ),
    );
  }
}
