import 'compounding_frequency.dart';
import 'fd_status.dart';
import 'payout_type.dart';

/// One Fixed Deposit record: everything needed to place it, track its
/// progress, and compute its maturity value.
///
/// Stored in Hive as a plain `Map<String, dynamic>` via [toMap]/[fromMap],
/// same hand-written-(de)serialization convention as every other model in
/// this app family — no generated `TypeAdapter`, no build_runner.
class FixedDeposit {
  const FixedDeposit({
    required this.id,
    required this.holderId,
    required this.bankName,
    required this.interestRatePercent,
    required this.principalAmount,
    required this.openedDate,
    required this.tenureMonths,
    required this.compounding,
    required this.payoutType,
    required this.autoRenew,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.fdNumber,
    this.closedDate,
    this.closedValue,
  });

  final String id;

  /// Which holder (see `features/holders`) this FD belongs to. Never null
  /// in practice — new deposits default to the auto-seeded Self holder.
  final String holderId;

  final String bankName;

  /// Annual nominal rate as a plain percentage, e.g. `7.4` for 7.4% p.a.
  final double interestRatePercent;

  final double principalAmount;
  final DateTime openedDate;
  final int tenureMonths;
  final CompoundingFrequency compounding;
  final PayoutType payoutType;
  final bool autoRenew;

  /// Optional free-text bank reference number, shown as Detail's subtitle.
  final String? fdNumber;

  final FdStatus status;

  /// Set only when [status] is [FdStatus.closedEarly].
  final DateTime? closedDate;

  /// Pro-rata payout computed at closure time — see
  /// `MaturityCalculator.closedEarlyValue`. Set only alongside [closedDate].
  final double? closedValue;

  final DateTime createdAt;
  final DateTime updatedAt;

  /// Derived, never stored, so it can never drift from [openedDate]/
  /// [tenureMonths]. Note: Dart's `DateTime` constructor normalizes a
  /// day-of-month that doesn't exist in the target month (e.g. 31 Jan + 1
  /// month lands on 2/3 Mar, not the last day of Feb) — a known, accepted
  /// MVP simplification rather than a bug to work around.
  DateTime get maturityDate => DateTime(openedDate.year, openedDate.month + tenureMonths, openedDate.day);

  bool isMaturedAsOf(DateTime asOf) => status == FdStatus.active && !asOf.isBefore(maturityDate);

  FixedDeposit copyWith({
    String? holderId,
    String? bankName,
    double? interestRatePercent,
    double? principalAmount,
    DateTime? openedDate,
    int? tenureMonths,
    CompoundingFrequency? compounding,
    PayoutType? payoutType,
    bool? autoRenew,
    String? fdNumber,
    FdStatus? status,
    DateTime? closedDate,
    double? closedValue,
    DateTime? updatedAt,
  }) {
    return FixedDeposit(
      id: id,
      holderId: holderId ?? this.holderId,
      bankName: bankName ?? this.bankName,
      interestRatePercent: interestRatePercent ?? this.interestRatePercent,
      principalAmount: principalAmount ?? this.principalAmount,
      openedDate: openedDate ?? this.openedDate,
      tenureMonths: tenureMonths ?? this.tenureMonths,
      compounding: compounding ?? this.compounding,
      payoutType: payoutType ?? this.payoutType,
      autoRenew: autoRenew ?? this.autoRenew,
      fdNumber: fdNumber ?? this.fdNumber,
      status: status ?? this.status,
      closedDate: closedDate ?? this.closedDate,
      closedValue: closedValue ?? this.closedValue,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'holderId': holderId,
      'bankName': bankName,
      'interestRatePercent': interestRatePercent,
      'principalAmount': principalAmount,
      'openedDate': openedDate.toIso8601String(),
      'tenureMonths': tenureMonths,
      'compounding': compounding.storageKey,
      'payoutType': payoutType.storageKey,
      'autoRenew': autoRenew,
      'fdNumber': fdNumber,
      'status': status.storageKey,
      'closedDate': closedDate?.toIso8601String(),
      'closedValue': closedValue,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory FixedDeposit.fromMap(Map<dynamic, dynamic> map) {
    return FixedDeposit(
      id: map['id'] as String,
      holderId: map['holderId'] as String,
      bankName: map['bankName'] as String,
      interestRatePercent: (map['interestRatePercent'] as num).toDouble(),
      principalAmount: (map['principalAmount'] as num).toDouble(),
      openedDate: DateTime.parse(map['openedDate'] as String),
      tenureMonths: map['tenureMonths'] as int,
      compounding: CompoundingFrequency.fromStorageKey(map['compounding'] as String),
      payoutType: PayoutType.fromStorageKey(map['payoutType'] as String),
      autoRenew: map['autoRenew'] as bool,
      fdNumber: map['fdNumber'] as String?,
      status: FdStatus.fromStorageKey(map['status'] as String),
      closedDate: (map['closedDate'] as String?) == null ? null : DateTime.parse(map['closedDate'] as String),
      closedValue: (map['closedValue'] as num?)?.toDouble(),
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }
}
