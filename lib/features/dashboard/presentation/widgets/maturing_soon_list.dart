import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/calculations/maturity_calculator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/initial_chip.dart';
import '../../../deposits/domain/fixed_deposit.dart';

/// The dashboard's "Maturing soon" mini-list (`.up-next`/`.mini-row`).
class MaturingSoonList extends StatelessWidget {
  const MaturingSoonList({super.key, required this.deposits});

  final List<FixedDeposit> deposits;

  @override
  Widget build(BuildContext context) {
    if (deposits.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text('No deposits yet — add your first one to see it here.', style: AppTypography.dateLine),
      );
    }
    return Column(
      children: [
        for (var i = 0; i < deposits.length; i++)
          _MiniRow(deposit: deposits[i], showDivider: i != deposits.length - 1),
      ],
    );
  }
}

class _MiniRow extends ConsumerWidget {
  const _MiniRow({required this.deposit, required this.showDivider});

  final FixedDeposit deposit;
  final bool showDivider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () => context.push('/deposits/${deposit.id}'),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: showDivider ? Border(bottom: BorderSide(color: AppColors.line)) : null,
        ),
        child: Row(
          children: [
            InitialChip(label: deposit.bankName),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(deposit.bankName, style: AppTypography.bankName),
                  Text(
                    'Matures ${DateFormat('d MMM yyyy').format(deposit.maturityDate)}',
                    style: AppTypography.dateLine,
                  ),
                ],
              ),
            ),
            Text(formatCurrency(ref, MaturityCalculator.maturityValue(deposit)), style: AppTypography.valueSmall),
          ],
        ),
      ),
    );
  }
}
