import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/calculations/maturity_calculator.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/fixedwise_card.dart';
import '../../../../core/widgets/initial_chip.dart';
import '../../../../core/widgets/linear_progress_track.dart';
import '../../domain/fd_status.dart';
import '../../domain/fixed_deposit.dart';
import 'fd_status_pill.dart';

/// One row on the deposits list (`.fd-card`): bank + rate/payout line,
/// amount, a progress-toward-maturity bar, and opened/matures dates.
class FdCard extends ConsumerWidget {
  const FdCard({super.key, required this.deposit});

  final FixedDeposit deposit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('MMM yyyy');
    // Closed/matured shows what it actually settled for rather than a
    // hypothetical full-maturity figure — matters most for closedEarly,
    // whose pro-rata payout is lower than maturityValue.
    final value = deposit.isClosed ? (deposit.closedValue ?? 0) : MaturityCalculator.maturityValue(deposit);
    return FixedwiseCard(
      onTap: () => context.push('/deposits/${deposit.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InitialChip(label: deposit.bankName),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(deposit.bankName, style: AppTypography.bankName),
                    Text(
                      '${formatRatePercent(deposit.interestRatePercent)}% p.a. · ${deposit.payoutType.label.toLowerCase()}',
                      style: AppTypography.rateLine,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(formatCurrency(ref, value), style: AppTypography.statFigure),
                  if (deposit.cardStatus != FdCardStatus.active) ...[
                    const SizedBox(height: 4),
                    FdStatusPill(deposit: deposit),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressTrack(fraction: MaturityCalculator.fdProgressFraction(deposit)),
          const SizedBox(height: 7),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Opened ${dateFormat.format(deposit.openedDate)}', style: AppTypography.footNote),
              Text('Matures ${dateFormat.format(deposit.maturityDate)}', style: AppTypography.footNote),
            ],
          ),
        ],
      ),
    );
  }
}
