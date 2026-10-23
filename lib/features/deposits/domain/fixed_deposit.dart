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
    this.tenureDays = 0,
    this.isTaxSaver = false,
    this.nomineeName,
    this.fdNumber,
    this.closedDate,
    this.closedValue,
    this.renewedFromId,
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

  /// Extra days on top of [tenureMonths] — Indian banks routinely sell
  /// odd tenures like "1 year 15 days" or "444 days" (0 months + 444
  /// days is just as valid as 14 months + 19 days).
  final int tenureDays;

  /// A Section 80C tax-saving FD: 5-year lock-in, no premature closure,
  /// and its principal (up to ₹1.5 lakh a year, old tax regime only)
  /// counts toward the 80C deduction.
  final bool isTaxSaver;

  /// Optional — who the bank pays on the holder's death. Kept so families
  /// can see at a glance which FDs still have no nomination.
  final String? nomineeName;
  final CompoundingFrequency compounding;
  final PayoutType payoutType;
  final bool autoRenew;

  /// Optional free-text bank reference number, shown as Detail's subtitle.
  final String? fdNumber;

  final FdStatus status;

  /// Set once [status] is [FdStatus.closedEarly] or [FdStatus.matured] —
  /// see [isClosed].
  final DateTime? closedDate;

  /// The payout recorded at closure time: pro-rata (see
  /// `MaturityCalculator.closedEarlyValue`) for [FdStatus.closedEarly], the
  /// full `MaturityCalculator.maturityValue` for [FdStatus.matured]. Set
  /// only alongside [closedDate].
  final double? closedValue;

  /// Set when this deposit was created by renewing another one (see
  /// `showRenewDepositFlow`) — the id of that original deposit, kept
  /// around (rather than deleted) purely as history. `null` for anything
  /// created directly through New Deposit.
  final String? renewedFromId;

  final DateTime createdAt;
  final DateTime updatedAt;

  /// Derived, never stored, so it can never drift from [openedDate]/
  /// [tenureMonths]/[tenureDays]. See [addTenure] for the month-end rule.
  DateTime get maturityDate => addTenure(openedDate, months: tenureMonths, days: tenureDays);

  /// "2 years 3 months", "444 days", "1 year 15 days" — the way Indian
  /// banks quote tenures.
  String get tenureLabel => describeTenure(tenureMonths, tenureDays);

  bool isMaturedAsOf(DateTime asOf) => status == FdStatus.active && !asOf.isBefore(maturityDate);

  /// Formally done, one way or the other — [FdStatus.closedEarly] or
  /// [FdStatus.matured]. `false` for a deposit that's quietly matured but
  /// hasn't been renewed/closed yet (see [isMaturedAsOf]) — it's still
  /// [FdStatus.active] until someone acts on it.
  bool get isClosed => status != FdStatus.active;

  /// How far ahead of maturity a still-running deposit starts being
  /// flagged as "maturing soon" — see [cardStatusAsOf].
  static const maturingSoonWindow = Duration(days: 7);

  /// Which of [FdCardStatus]'s three looks this deposit should render
  /// with as of [asOf] — feeds `FdCard`'s and the detail screen's status
  /// pill. Takes an explicit `asOf` (rather than always `DateTime.now()`)
  /// so it stays plain and testable, same convention as
  /// `MaturityCalculator`'s `asOf` parameters.
  FdCardStatus cardStatusAsOf(DateTime asOf) {
    if (isClosed || !asOf.isBefore(maturityDate)) return FdCardStatus.done;
    // asOf is strictly before maturityDate here, so this difference is
    // always positive.
    if (maturityDate.difference(asOf) <= maturingSoonWindow) return FdCardStatus.maturingSoon;
    return FdCardStatus.active;
  }

  FdCardStatus get cardStatus => cardStatusAsOf(DateTime.now());

  FixedDeposit copyWith({
    String? holderId,
    String? bankName,
    double? interestRatePercent,
    double? principalAmount,
    DateTime? openedDate,
    int? tenureMonths,
    int? tenureDays,
    bool? isTaxSaver,
    String? nomineeName,
    CompoundingFrequency? compounding,
    PayoutType? payoutType,
    bool? autoRenew,
    String? fdNumber,
    FdStatus? status,
    DateTime? closedDate,
    double? closedValue,
    String? renewedFromId,
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
      tenureDays: tenureDays ?? this.tenureDays,
      isTaxSaver: isTaxSaver ?? this.isTaxSaver,
      nomineeName: nomineeName ?? this.nomineeName,
      compounding: compounding ?? this.compounding,
      payoutType: payoutType ?? this.payoutType,
      autoRenew: autoRenew ?? this.autoRenew,
      fdNumber: fdNumber ?? this.fdNumber,
      status: status ?? this.status,
      closedDate: closedDate ?? this.closedDate,
      closedValue: closedValue ?? this.closedValue,
      renewedFromId: renewedFromId ?? this.renewedFromId,
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
      'tenureDays': tenureDays,
      'isTaxSaver': isTaxSaver,
      'nomineeName': nomineeName,
      'compounding': compounding.storageKey,
      'payoutType': payoutType.storageKey,
      'autoRenew': autoRenew,
      'fdNumber': fdNumber,
      'status': status.storageKey,
      'closedDate': closedDate?.toIso8601String(),
      'closedValue': closedValue,
      'renewedFromId': renewedFromId,
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
      // Absent on records saved before these fields existed.
      tenureDays: (map['tenureDays'] as int?) ?? 0,
      isTaxSaver: (map['isTaxSaver'] as bool?) ?? false,
      nomineeName: map['nomineeName'] as String?,
      compounding: CompoundingFrequency.fromStorageKey(map['compounding'] as String),
      payoutType: PayoutType.fromStorageKey(map['payoutType'] as String),
      autoRenew: map['autoRenew'] as bool,
      fdNumber: map['fdNumber'] as String?,
      status: FdStatus.fromStorageKey(map['status'] as String),
      closedDate: (map['closedDate'] as String?) == null ? null : DateTime.parse(map['closedDate'] as String),
      closedValue: (map['closedValue'] as num?)?.toDouble(),
      renewedFromId: map['renewedFromId'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }
}

/// [start] plus [months] calendar months, then [days] days — the way
/// banks compute a maturity date. A start day that doesn't exist in the
/// target month clamps to that month's last day (31 Jan + 1 month = 28/29
/// Feb), where Dart's own `DateTime` overflow would roll into March.
DateTime addTenure(DateTime start, {required int months, int days = 0}) {
  final lastDayOfTargetMonth = DateTime(start.year, start.month + months + 1, 0).day;
  final day = start.day > lastDayOfTargetMonth ? lastDayOfTargetMonth : start.day;
  return DateTime(start.year, start.month + months, day + days);
}

String describeTenure(int months, int days) {
  String plural(int n, String unit) => '$n $unit${n == 1 ? '' : 's'}';
  final years = months ~/ 12;
  final remainingMonths = months % 12;
  final parts = [
    if (years > 0) plural(years, 'year'),
    if (remainingMonths > 0) plural(remainingMonths, 'month'),
    if (days > 0) plural(days, 'day'),
  ];
  return parts.isEmpty ? '0 days' : parts.join(' ');
}
