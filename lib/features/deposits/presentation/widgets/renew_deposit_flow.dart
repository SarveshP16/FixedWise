import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/calculations/maturity_calculator.dart';
import '../../../../core/notifications/maturity_reminder_sync.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../application/fixed_deposits_providers.dart';
import '../../domain/fd_status.dart';
import '../../domain/fixed_deposit.dart';

/// Confirms and starts "Renew": if [deposit] is still just sitting there
/// matured (status still [FdStatus.active], past its own maturity date),
/// formally closes it out first — recording the full maturity value, same
/// as a plain close would — so it stops counting toward active totals and
/// keeps its place in history. Then opens New Deposit prefilled from it,
/// leaving the actual "create the new FD" step to the user (they may want
/// to adjust the rate for a fresh term) rather than assuming identical
/// terms.
///
/// No-ops (after confirming) for a deposit that's already been renewed —
/// callers should check `renewalOf` first and offer to view that instead.
Future<void> showRenewDepositFlow(BuildContext context, WidgetRef ref, FixedDeposit deposit) async {
  final alreadyClosed = deposit.isClosed;
  final finalValue = alreadyClosed ? (deposit.closedValue ?? 0) : MaturityCalculator.maturityValue(deposit);
  final dateFormat = DateFormat('d MMM yyyy');

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Renew this FD?'),
      content: Text(
        alreadyClosed
            ? "This opens a new deposit prefilled with ${deposit.bankName}'s details, "
                  'starting from its ${formatCurrency(ref, finalValue)} closing value. '
                  'This one stays in your history as closed.'
            : "This marks ${deposit.bankName}'s deposit matured on ${dateFormat.format(deposit.maturityDate)} "
                  'as closed, then opens a new deposit prefilled with its details, starting from its '
                  '${formatCurrency(ref, finalValue)} maturity value. It stays in your history as matured.',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Renew')),
      ],
    ),
  );

  if (confirmed != true) return;

  if (!alreadyClosed) {
    await ref
        .read(fixedDepositsProvider.notifier)
        .update(
          deposit.copyWith(status: FdStatus.matured, closedDate: deposit.maturityDate, closedValue: finalValue),
        );
    await onDepositRemoved(deposit.id);
  }

  if (context.mounted) context.push('/deposits/new?renewFrom=${deposit.id}');
}

/// The deposit (if any) created by renewing [depositId], found by scanning
/// [all] for a matching [FixedDeposit.renewedFromId] — kept as a plain
/// linear scan rather than an index since a holder's whole FD list is
/// small and this is only looked up once per detail-screen build.
FixedDeposit? findRenewalOf(List<FixedDeposit> all, String depositId) {
  for (final candidate in all) {
    if (candidate.renewedFromId == depositId) return candidate;
  }
  return null;
}
