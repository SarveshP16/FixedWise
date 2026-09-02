import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// A small rounded status pill (`.pill`) — used for the dashboard's growth
/// delta ("↑ 15.8% overall growth").
class PillBadge extends StatelessWidget {
  const PillBadge({super.key, required this.label, this.background, this.textColor});

  final String label;
  final Color? background;
  final Color? textColor;

  /// The mockup's "on dark" variant used inside the hero header — a more
  /// translucent sage fill with lighter text than the default.
  const PillBadge.onDark({super.key, required this.label})
    : background = AppColors.deltaPillBackground,
      textColor = AppColors.deltaPillText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: background ?? AppColors.sageTint,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: AppTypography.pillLabel.copyWith(color: textColor ?? AppColors.growthText)),
    );
  }
}
