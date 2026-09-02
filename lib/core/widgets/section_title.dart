import 'package:flutter/material.dart';

import '../theme/app_typography.dart';

/// A muted uppercase-feeling section header like "Maturity ladder" or
/// "Maturing soon" (`.sec-title`).
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.padding = const EdgeInsets.only(bottom: 12)});

  final String text;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(padding: padding, child: Text(text, style: AppTypography.sectionTitle));
  }
}
