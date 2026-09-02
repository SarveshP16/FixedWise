import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A square, bordered icon button (`.icon-btn`) — used for back buttons and
/// the deposits list's filter/menu button.
class BorderedIconButton extends StatelessWidget {
  const BorderedIconButton({super.key, required this.icon, required this.onTap, this.size = 34});

  final IconData icon;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: AppColors.ink),
        ),
      ),
    );
  }
}
