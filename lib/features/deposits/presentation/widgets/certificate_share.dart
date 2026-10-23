import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/calculations/maturity_calculator.dart';
import '../../../../core/utils/currency_formatter.dart' show formatRatePercent;
import '../../domain/fixed_deposit.dart';

/// "Download certificate" for MVP: the app can't produce a real bank
/// certificate, so this shares a plain formatted-text summary through the
/// OS share sheet instead. A real PDF is a later nice-to-have.
Future<void> shareDepositCertificate(FixedDeposit deposit, {required String currencySymbol}) {
  final dateFormat = DateFormat('d MMM yyyy');
  String money(num amount) => '$currencySymbol${NumberFormat('#,##,##0', 'en_IN').format(amount)}';

  final lines = [
    deposit.bankName,
    if (deposit.fdNumber != null && deposit.fdNumber!.isNotEmpty) 'FD number: ${deposit.fdNumber}',
    '',
    'Principal: ${money(deposit.principalAmount)}',
    'Interest rate: ${formatRatePercent(deposit.interestRatePercent)}% p.a. (${deposit.compounding.label.toLowerCase()}, ${deposit.payoutType.label.toLowerCase()})',
    'Tenure: ${deposit.tenureLabel}',
    if (deposit.isTaxSaver) 'Tax-saver FD (Section 80C, 5-year lock-in)',
    'Opened: ${dateFormat.format(deposit.openedDate)}',
    'Matures: ${dateFormat.format(deposit.maturityDate)}',
    'Value at maturity: ${money(MaturityCalculator.maturityValue(deposit))}',
    '',
    'Shared from FixedWise',
  ];

  return SharePlus.instance.share(ShareParams(text: lines.join('\n'), subject: '${deposit.bankName} — Fixed Deposit'));
}
