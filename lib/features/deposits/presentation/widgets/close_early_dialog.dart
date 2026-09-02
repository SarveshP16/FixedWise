import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/calculations/maturity_calculator.dart';
import '../../../../core/notifications/maturity_reminder_sync.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../application/fixed_deposits_providers.dart';
import '../../domain/fd_status.dart';
import '../../domain/fixed_deposit.dart';

/// Confirms and applies "Close early": shows the computed pro-rata payout
/// before committing, then marks the deposit [FdStatus.closedEarly].
Future<void> showCloseEarlyDialog(BuildContext context, WidgetRef ref, FixedDeposit deposit) async {
  final closedDate = DateTime.now();
  final closedValue = MaturityCalculator.fdClosedEarlyValue(deposit, closedDate: closedDate);
  final amountText = formatCurrency(ref, closedValue);

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Close this FD early?'),
      content: Text(
        'Based on simple pro-rata interest for the time held so far, '
        'you would receive approximately $amountText today instead of '
        'waiting for maturity. Your bank\'s actual early-closure terms '
        'may differ.',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Close FD')),
      ],
    ),
  );

  if (confirmed != true) return;

  await ref
      .read(fixedDepositsProvider.notifier)
      .update(
        deposit.copyWith(status: FdStatus.closedEarly, closedDate: closedDate, closedValue: closedValue),
      );
  await onDepositRemoved(deposit.id);
}
