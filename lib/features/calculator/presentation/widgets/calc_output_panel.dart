import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/calculations/maturity_calculator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../deposits/domain/draft_deposit.dart';
import '../../../deposits/domain/payout_type.dart';

/// The live-calculator's dark output panel (`.calc-out`) — recomputes on
/// every keystroke/slider move via [MaturityCalculator]'s raw functions,
/// matching (and fixing) the mockup's own live-recalculation script.
class CalcOutputPanel extends ConsumerWidget {
  const CalcOutputPanel({super.key, required this.draft});

  final DraftDeposit draft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final maturity = MaturityCalculator.maturityValueRaw(
      principal: draft.principalAmount,
      ratePercent: draft.interestRatePercent,
      periodsPerYear: draft.compounding.periodsPerYear,
      tenureMonths: draft.tenureMonths,
      tenureDays: draft.tenureDays,
      payoutType: draft.payoutType,
    );
    final interest = MaturityCalculator.interestEarnedRaw(
      principal: draft.principalAmount,
      ratePercent: draft.interestRatePercent,
      periodsPerYear: draft.compounding.periodsPerYear,
      tenureMonths: draft.tenureMonths,
      tenureDays: draft.tenureDays,
      payoutType: draft.payoutType,
    );
    final shortTerm =
        MaturityCalculator.tenureYears(draft.tenureMonths, draft.tenureDays) < MaturityCalculator.shortTermYears;

    final isPayout = draft.payoutType == PayoutType.payout;
    final secondaryLine = isPayout
        ? 'Paid out per ${_periodNoun(draft.compounding.periodsPerYear)}: '
              '${formatCurrency(ref, MaturityCalculator.payoutPerPeriodRaw(
                principal: draft.principalAmount,
                ratePercent: draft.interestRatePercent,
                periodsPerYear: draft.compounding.periodsPerYear,
              ))}'
        : 'Interest earned: ${formatCurrency(ref, interest)}';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 22),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isPayout ? 'Principal returned at maturity' : 'Estimated value at maturity',
            style: AppTypography.calcLabel,
          ),
          Text(formatCurrency(ref, maturity), style: AppTypography.calcFigure),
          const SizedBox(height: 10),
          Text(secondaryLine, style: AppTypography.calcLabel),
          if (isPayout) Text('Total interest over term: ${formatCurrency(ref, interest)}', style: AppTypography.calcLabel),
          if (shortTerm && !isPayout)
            Text('Under 6 months: banks pay simple interest at maturity', style: AppTypography.calcLabel),
        ],
      ),
    );
  }

  String _periodNoun(int periodsPerYear) {
    switch (periodsPerYear) {
      case 12:
        return 'month';
      case 4:
        return 'quarter';
      case 2:
        return 'half-year';
      default:
        return 'year';
    }
  }
}
