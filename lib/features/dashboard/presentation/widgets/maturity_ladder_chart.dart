import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/calculations/maturity_calculator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../deposits/domain/fixed_deposit.dart';

/// The dashboard's "Maturity ladder" bar chart (`.ladder`): one bar per
/// upcoming maturity, its height proportional to that deposit's eventual
/// maturity value (not its value-so-far), with the amount labeled above
/// the bar and the maturity month/year below it.
class MaturityLadderChart extends ConsumerWidget {
  const MaturityLadderChart({super.key, required this.deposits});

  final List<FixedDeposit> deposits;

  static List<Color> get _barColors => [
    AppColors.ladderStep1,
    AppColors.ladderStep2,
    AppColors.ladderStep3,
    AppColors.ladderStep4,
  ];

  /// Total height reserved for the bar area, including headroom above the
  /// tallest possible bar for its amount label.
  static const _areaHeight = 112.0;

  /// The tallest a bar itself can be within [_areaHeight], leaving the
  /// rest as label headroom.
  static const _maxBarHeight = 92.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (deposits.isEmpty) {
      return SizedBox(
        height: _areaHeight,
        child: Center(child: Text('No upcoming maturities yet', style: AppTypography.ladderDateLabel)),
      );
    }

    final values = deposits.map(MaturityCalculator.maturityValue).toList();
    final maxValue = values.reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: _areaHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < deposits.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(
                  child: _Bar(
                    height: maxValue <= 0 ? _maxBarHeight * 0.15 : (_maxBarHeight * (values[i] / maxValue)).clamp(
                      _maxBarHeight * 0.15,
                      _maxBarHeight,
                    ),
                    color: _barColors[i % _barColors.length],
                    amountLabel: formatCurrency(ref, values[i]),
                    labelOnDark: i == deposits.length - 1,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var i = 0; i < deposits.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(
                child: Text(
                  DateFormat('MMM\nyyyy').format(deposits[i].maturityDate),
                  textAlign: TextAlign.center,
                  style: AppTypography.ladderDateLabel,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.height, required this.color, required this.amountLabel, required this.labelOnDark});

  final double height;
  final Color color;
  final String amountLabel;

  /// The tallest/last bar in the mockup is dark enough (`brassDeep`) that
  /// its own amount label is shown in light text sitting inside the bar's
  /// top edge rather than above it, matching `.ladder .bar .amt` on the
  /// darkest step.
  final bool labelOnDark;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      clipBehavior: Clip.none,
      children: [
        Container(
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6), bottom: Radius.circular(3)),
          ),
        ),
        // Painted after (on top of) the bar fill above — the on-bar
        // (labelOnDark) case positions this inside the bar's own height,
        // so it'd otherwise be hidden behind that Container.
        Positioned(
          bottom: labelOnDark ? height - 16 : height + 2,
          child: Text(
            amountLabel,
            style: AppTypography.ladderAmount.copyWith(color: labelOnDark ? AppColors.heroOnDark : AppColors.text),
            softWrap: false,
          ),
        ),
      ],
    );
  }
}
