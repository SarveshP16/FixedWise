import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A thin rounded progress track (`.progress`/`i`) showing how far a
/// deposit has progressed toward maturity.
class LinearProgressTrack extends StatelessWidget {
  const LinearProgressTrack({super.key, required this.fraction, this.height = 4});

  /// 0.0–1.0, already clamped by the caller (see
  /// `MaturityCalculator.progressFraction`).
  final double fraction;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              Container(height: height, color: AppColors.line),
              Container(height: height, width: constraints.maxWidth * fraction, color: AppColors.brass),
            ],
          );
        },
      ),
    );
  }
}
