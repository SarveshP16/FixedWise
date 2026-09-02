import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Row of filled/unfilled circles showing PIN entry progress.
class PinDots extends StatelessWidget {
  const PinDots({super.key, required this.digitCount, required this.enteredLength});

  final int digitCount;
  final int enteredLength;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < digitCount; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < enteredLength ? AppColors.brass : Colors.transparent,
                border: Border.all(color: i < enteredLength ? AppColors.brass : AppColors.line, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}
