import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/pill_badge.dart';
import '../../../profile/application/settings_providers.dart';

/// The dark, rounded-bottom hero at the top of the dashboard (`.hero`):
/// a time-of-day greeting, the total-across-deposits figure, and an
/// overall-growth pill.
class HeroHeader extends ConsumerWidget {
  const HeroHeader({super.key, required this.totalValue, required this.growthPercent});

  final double totalValue;
  final double growthPercent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(displayNameProvider);
    final isGain = growthPercent >= 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 22),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 14),
            Text('${_greeting()}, $name', style: AppTypography.heroLabel),
            const SizedBox(height: 14),
            Text('Total across deposits', style: AppTypography.heroLabel),
            Text(formatCurrency(ref, totalValue), style: AppTypography.displayTotal),
            const SizedBox(height: 10),
            PillBadge.onDark(
              label: '${isGain ? '↑' : '↓'} ${growthPercent.abs().toStringAsFixed(1)}% overall growth',
            ),
          ],
        ),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}
