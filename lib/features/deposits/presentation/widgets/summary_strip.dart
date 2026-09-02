import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/calculations/maturity_calculator.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/fixedwise_card.dart';
import '../../domain/fd_status.dart';
import '../../domain/fixed_deposit.dart';

/// The deposits list's summary strip (`.summary-strip`): active count,
/// total invested, and total value at maturity — computed over active
/// deposits in the current holder filter.
class SummaryStrip extends ConsumerWidget {
  const SummaryStrip({super.key, required this.deposits});

  final List<FixedDeposit> deposits;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = deposits.where((fd) => fd.status == FdStatus.active).toList();
    final invested = active.fold<double>(0, (sum, fd) => sum + fd.principalAmount);
    final atMaturity = active.fold<double>(0, (sum, fd) => sum + MaturityCalculator.maturityValue(fd));

    return FixedwiseCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _Cell(value: '${active.length}', label: 'Active'),
          _Cell(value: formatCurrency(ref, invested), label: 'Invested'),
          _Cell(value: formatCurrency(ref, atMaturity), label: 'At maturity'),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: AppTypography.statFigure),
        const SizedBox(height: 2),
        Text(label, style: AppTypography.statLabel),
      ],
    );
  }
}
