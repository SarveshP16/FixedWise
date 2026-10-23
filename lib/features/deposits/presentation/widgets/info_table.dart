import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/fixed_deposit.dart';
import '../../domain/payout_type.dart';

/// Detail screen's key/value info table (`.table .r`).
class InfoTable extends ConsumerWidget {
  const InfoTable({super.key, required this.deposit});

  final FixedDeposit deposit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('d MMM yyyy');
    final rows = <(String, String)>[
      ('Principal', formatCurrency(ref, deposit.principalAmount)),
      ('Interest rate', '${formatRatePercent(deposit.interestRatePercent)}% p.a.'),
      ('Tenure', deposit.tenureLabel),
      (deposit.payoutType == PayoutType.payout ? 'Interest paid' : 'Compounding', deposit.compounding.label),
      ('Payout type', deposit.payoutType.label),
      if (deposit.isTaxSaver) ('Tax saver (80C)', '5-year lock-in'),
      ('Nominee', deposit.nomineeName ?? 'Not recorded'),
      ('Opened', dateFormat.format(deposit.openedDate)),
      ('Matures', dateFormat.format(deposit.maturityDate)),
      ('Auto-renew', deposit.autoRenew ? 'On' : 'Off'),
    ];

    return Container(
      decoration: BoxDecoration(border: Border(top: BorderSide(color: AppColors.line))),
      child: Column(
        children: [
          for (final row in rows)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(row.$1, style: AppTypography.tableKey),
                  Text(row.$2, style: AppTypography.tableValue),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
