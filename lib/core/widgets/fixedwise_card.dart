import 'package:flutter/material.dart';

/// A `.card`-styled container: the theme's [CardThemeData] already supplies
/// the fill/border/radius, so this just standardizes padding — the mockup
/// uses a different padding per card (`.fd-card` 14px, `.summary-strip`
/// 14px/16px, etc.), so [padding] is the one thing each call site sets.
class FixedwiseCard extends StatelessWidget {
  const FixedwiseCard({super.key, required this.child, this.padding = const EdgeInsets.all(14), this.onTap});

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Card(
      child: Padding(padding: padding, child: child),
    );
    if (onTap == null) return card;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: Padding(padding: padding, child: child)),
    );
  }
}
