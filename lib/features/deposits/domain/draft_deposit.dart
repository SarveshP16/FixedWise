import 'compounding_frequency.dart';
import 'payout_type.dart';

/// A not-yet-created FD's editable fields — what the New Deposit form and
/// the standalone Calculator tab both need before (or instead of) a real
/// [FixedDeposit] exists. Kept separate from [FixedDeposit] itself since a
/// draft has no id/holder/status yet and the Calculator tab never
/// persists one at all.
class DraftDeposit {
  const DraftDeposit({
    required this.bankName,
    required this.interestRatePercent,
    required this.principalAmount,
    required this.tenureMonths,
    this.tenureDays = 0,
    required this.compounding,
    required this.payoutType,
  });

  factory DraftDeposit.initial() => const DraftDeposit(
    bankName: '',
    interestRatePercent: 7.0,
    principalAmount: 10000,
    tenureMonths: 24,
    compounding: CompoundingFrequency.quarterly,
    payoutType: PayoutType.cumulative,
  );

  final String bankName;
  final double interestRatePercent;
  final double principalAmount;
  final int tenureMonths;
  final int tenureDays;
  final CompoundingFrequency compounding;
  final PayoutType payoutType;

  DraftDeposit copyWith({
    String? bankName,
    double? interestRatePercent,
    double? principalAmount,
    int? tenureMonths,
    int? tenureDays,
    CompoundingFrequency? compounding,
    PayoutType? payoutType,
  }) {
    return DraftDeposit(
      bankName: bankName ?? this.bankName,
      interestRatePercent: interestRatePercent ?? this.interestRatePercent,
      principalAmount: principalAmount ?? this.principalAmount,
      tenureMonths: tenureMonths ?? this.tenureMonths,
      tenureDays: tenureDays ?? this.tenureDays,
      compounding: compounding ?? this.compounding,
      payoutType: payoutType ?? this.payoutType,
    );
  }

  /// At least 7 days — the shortest FD Indian banks accept.
  bool get hasValidTenure => tenureMonths * 30 + tenureDays >= 7;
}
