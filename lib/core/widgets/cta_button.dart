import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// The full-width brass call-to-action button (`.cta`) — used once per
/// form, e.g. New Deposit's "Create deposit".
class CtaButton extends StatelessWidget {
  const CtaButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brass,
          foregroundColor: AppColors.ctaText,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
          elevation: 0,
        ),
        child: Text(label, style: AppTypography.ctaLabel),
      ),
    );
  }
}
