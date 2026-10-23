import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/calculations/maturity_calculator.dart';
import '../../../../core/notifications/maturity_reminder_sync.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../application/fixed_deposits_providers.dart';
import '../../domain/fd_status.dart';
import '../../domain/fixed_deposit.dart';

/// Confirms and applies "Close early": estimates the payout after the
/// bank's premature-withdrawal penalty, lets the user correct either the
/// penalty or the amount actually credited, then marks the deposit
/// [FdStatus.closedEarly]. Tax-saver FDs can't be closed early at all
/// (Section 80C lock-in), so for those this only explains why.
Future<void> showCloseEarlyDialog(BuildContext context, WidgetRef ref, FixedDeposit deposit) async {
  if (deposit.isTaxSaver && DateTime.now().isBefore(addTenure(deposit.openedDate, months: 60))) {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Locked until 5 years'),
        content: const Text(
          'Tax-saver FDs under Section 80C have a 5-year lock-in — banks only release them early on the '
          "holder's death. If that's what happened, contact the bank, then record the payout here once it's received.",
        ),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK'))],
      ),
    );
    return;
  }

  final closedValue = await showDialog<double>(
    context: context,
    builder: (context) => _CloseEarlyDialog(deposit: deposit, format: (amount) => formatCurrency(ref, amount)),
  );
  if (closedValue == null) return;

  await ref
      .read(fixedDepositsProvider.notifier)
      .update(deposit.copyWith(status: FdStatus.closedEarly, closedDate: DateTime.now(), closedValue: closedValue));
  await onDepositRemoved(deposit.id);
}

class _CloseEarlyDialog extends StatefulWidget {
  const _CloseEarlyDialog({required this.deposit, required this.format});

  final FixedDeposit deposit;
  final String Function(num) format;

  @override
  State<_CloseEarlyDialog> createState() => _CloseEarlyDialogState();
}

class _CloseEarlyDialogState extends State<_CloseEarlyDialog> {
  late final TextEditingController _penaltyController;
  late final TextEditingController _amountController;

  /// Once the user types the amount the bank actually credited, a later
  /// penalty edit must not overwrite it.
  bool _amountEdited = false;

  @override
  void initState() {
    super.initState();
    final penalty = MaturityCalculator.defaultPrematurePenaltyPercent(widget.deposit.principalAmount);
    _penaltyController = TextEditingController(text: formatRatePercent(penalty));
    _amountController = TextEditingController(text: _estimate(penalty).round().toString());
  }

  @override
  void dispose() {
    _penaltyController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  double _estimate(double penalty) =>
      MaturityCalculator.fdClosedEarlyValue(widget.deposit, closedDate: DateTime.now(), penaltyPercent: penalty);

  @override
  Widget build(BuildContext context) {
    final amount = double.tryParse(_amountController.text);
    return AlertDialog(
      title: const Text('Close this FD early?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Banks pay interest for the time held, minus a premature-withdrawal penalty (usually 0.5–1%). '
              "Adjust the penalty to your bank's, or enter the exact amount credited.",
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _penaltyController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
              decoration: const InputDecoration(labelText: 'Penalty', suffixText: '% p.a.'),
              onChanged: (value) {
                if (_amountEdited) return;
                setState(() => _amountController.text = _estimate(double.tryParse(value) ?? 0).round().toString());
              },
            ),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: 'Amount received', prefixText: currencySymbol),
              onChanged: (_) => setState(() => _amountEdited = true),
            ),
            const SizedBox(height: 8),
            Text('Principal was ${widget.format(widget.deposit.principalAmount)}.'),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          onPressed: amount == null || amount <= 0 ? null : () => Navigator.of(context).pop(amount),
          child: const Text('Close FD'),
        ),
      ],
    );
  }
}
