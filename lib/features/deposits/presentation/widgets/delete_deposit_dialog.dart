import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/notifications/maturity_reminder_sync.dart';
import '../../application/fixed_deposits_providers.dart';
import '../../domain/fixed_deposit.dart';

/// Confirms and permanently removes [deposit] — there's no undo, so this
/// always asks first. Returns whether it was actually deleted, so the
/// caller (the detail screen) knows to navigate away.
Future<bool> showDeleteDepositDialog(BuildContext context, WidgetRef ref, FixedDeposit deposit) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete this deposit?'),
      content: Text(
        "This removes the ${deposit.bankName} deposit and its history for good — there's no undo.",
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );

  if (confirmed != true) return false;

  await ref.read(fixedDepositsProvider.notifier).delete(deposit.id);
  await onDepositRemoved(deposit.id);
  return true;
}
