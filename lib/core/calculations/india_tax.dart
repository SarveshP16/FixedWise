import 'dart:math' as math;

import '../../features/deposits/domain/fd_status.dart';
import '../../features/deposits/domain/fixed_deposit.dart';
import '../../features/deposits/domain/payout_type.dart';
import '../../features/holders/domain/holder.dart';
import 'maturity_calculator.dart';

/// India's April–March financial year, named by the calendar year it
/// starts in (`FinancialYear(2025)` is FY 2025-26).
class FinancialYear {
  const FinancialYear(this.startYear);

  factory FinancialYear.containing(DateTime date) => FinancialYear(date.month >= 4 ? date.year : date.year - 1);

  final int startYear;

  DateTime get start => DateTime(startYear, 4, 1);

  /// Exclusive — 1 April of the following year.
  DateTime get end => DateTime(startYear + 1, 4, 1);

  String get label => 'FY $startYear-${((startYear + 1) % 100).toString().padLeft(2, '0')}';

  FinancialYear get previous => FinancialYear(startYear - 1);

  FinancialYear get next => FinancialYear(startYear + 1);

  @override
  bool operator ==(Object other) => other is FinancialYear && other.startYear == startYear;

  @override
  int get hashCode => startYear.hashCode;
}

/// TDS on FD interest under Section 194A, at 10% when the depositor's PAN
/// is on record (20% without one).
const tdsRatePercent = 10;

/// The interest a bank can pay a depositor in a financial year before it
/// must deduct TDS — per bank, across all its branches. Budget 2025
/// raised it from FY 2025-26 on (₹40,000 → ₹50,000, and for senior
/// citizens ₹50,000 → ₹1,00,000).
double tdsThresholdFor(FinancialYear year, {required bool seniorCitizen}) {
  if (year.startYear >= 2025) return seniorCitizen ? 100000 : 50000;
  return seniorCitizen ? 50000 : 40000;
}

/// DICGC deposit insurance: up to ₹5 lakh per depositor per bank,
/// principal and interest together, across every account they hold
/// there in the same capacity.
const dicgcCoverLimit = 500000.0;

/// The date a deposit stopped earning interest — its closure date if it
/// was closed early, otherwise its maturity date.
DateTime _interestEnd(FixedDeposit fd) {
  if (fd.status == FdStatus.closedEarly && fd.closedDate != null) return fd.closedDate!;
  return fd.maturityDate;
}

/// Interest [fd] earned between [from] (inclusive) and [to] (exclusive),
/// on an accrual basis — the way banks report it for TDS, and the way
/// cumulative FD interest is usually declared each year. Payout FDs earn
/// simple interest day by day; cumulative ones by the difference in their
/// accrued value; an FD closed early spreads the interest it actually
/// paid evenly over the days it was held.
double interestAccruedBetween(FixedDeposit fd, DateTime from, DateTime to) {
  final end = _interestEnd(fd);
  final windowStart = fd.openedDate.isAfter(from) ? fd.openedDate : from;
  final windowEnd = end.isBefore(to) ? end : to;
  if (!windowEnd.isAfter(windowStart)) return 0;

  if (fd.status == FdStatus.closedEarly) {
    final heldDays = MaturityCalculator.daysBetween(fd.openedDate, end);
    if (heldDays <= 0) return 0;
    final totalInterest = math.max(0.0, (fd.closedValue ?? fd.principalAmount) - fd.principalAmount);
    return totalInterest * MaturityCalculator.daysBetween(windowStart, windowEnd) / heldDays;
  }

  if (fd.payoutType == PayoutType.payout) {
    return fd.principalAmount * fd.interestRatePercent / 100 * MaturityCalculator.daysBetween(windowStart, windowEnd) / 365;
  }
  return MaturityCalculator.fdAccruedValue(fd, asOf: windowEnd) - MaturityCalculator.fdAccruedValue(fd, asOf: windowStart);
}

/// One holder's FDs at one bank — the unit both TDS and DICGC cover are
/// worked out on.
class HolderBankSummary {
  const HolderBankSummary({
    required this.holder,
    required this.bankName,
    required this.interest,
    required this.tdsThreshold,
    required this.insuredExposure,
  });

  final Holder holder;
  final String bankName;

  /// Interest accrued in the financial year being looked at.
  final double interest;
  final double tdsThreshold;

  /// Principal plus interest accrued so far, across this holder's still-
  /// running FDs at this bank, as of today.
  final double insuredExposure;

  bool get tdsLikely => interest > tdsThreshold;

  /// What the bank would deduct, assuming PAN is on record and no Form
  /// 15G/15H has been submitted.
  double get estimatedTds => tdsLikely ? interest * tdsRatePercent / 100 : 0;

  bool get exceedsDicgcCover => insuredExposure > dicgcCoverLimit;
}

/// Groups [deposits] by holder and bank (bank names compared ignoring
/// case and surrounding spaces) for [year], dropping groups with nothing
/// to show — no interest that year and nothing still running.
List<HolderBankSummary> summariseByHolderAndBank({
  required List<FixedDeposit> deposits,
  required List<Holder> holders,
  required FinancialYear year,
  DateTime? asOf,
}) {
  final now = asOf ?? DateTime.now();
  final holdersById = {for (final holder in holders) holder.id: holder};
  final groups = <(String, String), List<FixedDeposit>>{};
  for (final fd in deposits) {
    if (!holdersById.containsKey(fd.holderId)) continue;
    groups.putIfAbsent((fd.holderId, fd.bankName.trim().toLowerCase()), () => []).add(fd);
  }

  final summaries = <HolderBankSummary>[];
  for (final MapEntry(key: (holderId, _), value: group) in groups.entries) {
    final holder = holdersById[holderId]!;
    final interest = group.fold(0.0, (sum, fd) => sum + interestAccruedBetween(fd, year.start, year.end));
    final exposure = group
        .where((fd) => fd.status == FdStatus.active)
        .fold(0.0, (sum, fd) => sum + MaturityCalculator.fdAccruedValue(fd, asOf: now));
    if (interest <= 0 && exposure <= 0) continue;
    summaries.add(
      HolderBankSummary(
        holder: holder,
        bankName: group.first.bankName.trim(),
        interest: interest,
        tdsThreshold: tdsThresholdFor(year, seniorCitizen: holder.isSeniorCitizen),
        insuredExposure: exposure,
      ),
    );
  }
  summaries.sort((a, b) {
    final byHolder = a.holder.createdAt.compareTo(b.holder.createdAt);
    return byHolder != 0 ? byHolder : a.bankName.toLowerCase().compareTo(b.bankName.toLowerCase());
  });
  return summaries;
}
