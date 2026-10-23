import 'dart:math' as math;

import '../../features/deposits/domain/fd_status.dart';
import '../../features/deposits/domain/fixed_deposit.dart';
import '../../features/deposits/domain/payout_type.dart';
import 'chart_point.dart';

/// Every FD interest/maturity/progress formula, in one pure, dependency-
/// free place — no Hive, no Riverpod, no I/O — so it's directly
/// unit-testable and shared by the dashboard, deposits list/detail, the
/// standalone calculator, and the New Deposit form.
///
/// Two layers: the `*Raw` functions work on plain numbers (used by the New
/// Deposit form and Calculator tab, which don't have a [FixedDeposit] yet
/// while the user is still typing); the rest take a [FixedDeposit] and
/// delegate to the raw functions, used by Dashboard/Deposits/Detail once a
/// record actually exists.
abstract final class MaturityCalculator {
  /// Indian banks pay plain simple interest on deposits shorter than six
  /// months, whatever compounding the scheme otherwise uses.
  static const shortTermYears = 0.5;

  /// Whole calendar days from [from] to [to], ignoring time of day and
  /// immune to DST shifts (a raw `difference().inDays` across a DST change
  /// comes up an hour — and so a whole day — short).
  static int daysBetween(DateTime from, DateTime to) =>
      DateTime.utc(to.year, to.month, to.day).difference(DateTime.utc(from.year, from.month, from.day)).inDays;

  /// [months] + [days] as years — banks count days on an actual/365 basis.
  static double tenureYears(int months, int days) => months / 12 + days / 365;

  /// What [principal] grows to over [years] when interest is reinvested,
  /// the way Indian banks compute it (IBA convention): compounded for
  /// every *complete* period, then simple interest on that compounded
  /// amount for the leftover "broken" days — e.g. 13 months quarterly is
  /// 4 compounded quarters plus one month of simple interest. For whole-
  /// period tenures this is exactly `P·(1+r/n)^(n·t)` (the mockup's own
  /// formula, pinned in `maturity_calculator_test.dart`). [shortTerm]
  /// (a sub-six-month tenure) switches to simple interest throughout.
  static double _cumulativeValue({
    required double principal,
    required double ratePercent,
    required int periodsPerYear,
    required double years,
    required bool shortTerm,
  }) {
    final r = ratePercent / 100;
    if (years <= 0) return principal;
    if (shortTerm) return principal * (1 + r * years);
    // The epsilon keeps e.g. 24/12*4 = 7.999… from flooring to 7.
    final fullPeriods = (years * periodsPerYear + 1e-9).floor();
    final brokenYears = math.max(0.0, years - fullPeriods / periodsPerYear);
    return principal * math.pow(1 + r / periodsPerYear, fullPeriods) * (1 + r * brokenYears);
  }

  /// Maturity value: see [_cumulativeValue] for a cumulative FD; for a
  /// payout FD, interest is disbursed each period rather than reinvested,
  /// so the principal alone is what's returned at maturity.
  static double maturityValueRaw({
    required double principal,
    required double ratePercent,
    required int periodsPerYear,
    required int tenureMonths,
    int tenureDays = 0,
    required PayoutType payoutType,
  }) {
    if (payoutType == PayoutType.payout) return principal;
    final years = tenureYears(tenureMonths, tenureDays);
    return _cumulativeValue(
      principal: principal,
      ratePercent: ratePercent,
      periodsPerYear: periodsPerYear,
      years: years,
      shortTerm: years < shortTermYears,
    );
  }

  /// Total interest over the full term: for cumulative, the compounded
  /// gain over principal; for payout, the simple (non-compounding) amount
  /// actually disbursed across the term.
  static double interestEarnedRaw({
    required double principal,
    required double ratePercent,
    required int periodsPerYear,
    required int tenureMonths,
    int tenureDays = 0,
    required PayoutType payoutType,
  }) {
    if (payoutType == PayoutType.payout) {
      return principal * (ratePercent / 100) * tenureYears(tenureMonths, tenureDays);
    }
    return maturityValueRaw(
          principal: principal,
          ratePercent: ratePercent,
          periodsPerYear: periodsPerYear,
          tenureMonths: tenureMonths,
          tenureDays: tenureDays,
          payoutType: payoutType,
        ) -
        principal;
  }

  /// The amount disbursed each compounding period for a payout FD, e.g.
  /// "₹185 every quarter". Meaningless for a cumulative FD (nothing is
  /// paid out along the way), so callers should only surface this when
  /// [PayoutType.payout] is selected.
  static double payoutPerPeriodRaw({
    required double principal,
    required double ratePercent,
    required int periodsPerYear,
  }) {
    final r = ratePercent / 100;
    return principal * r / periodsPerYear;
  }

  /// Fraction of the FD's term elapsed as of [asOf] (defaults to now),
  /// clamped to `[0, 1]` — feeds every progress bar.
  static double progressFraction({required DateTime openedDate, required DateTime maturityDate, DateTime? asOf}) {
    final now = asOf ?? DateTime.now();
    final totalDays = maturityDate.difference(openedDate).inDays;
    if (totalDays <= 0) return 1;
    final elapsedDays = now.difference(openedDate).inDays;
    return (elapsedDays / totalDays).clamp(0, 1).toDouble();
  }

  /// Value accrued so far (not the final maturity value): a cumulative FD
  /// grows by the same complete-periods-plus-broken-days rule as
  /// [maturityValueRaw], applied to the time elapsed — exactly [principal]
  /// at the start and exactly [maturityValueRaw] at maturity — while a
  /// payout FD's book value never grows (its interest is disbursed, not
  /// retained).
  static double accruedValueAt({
    required double principal,
    required double ratePercent,
    required int periodsPerYear,
    required int tenureMonths,
    int tenureDays = 0,
    required PayoutType payoutType,
    required DateTime openedDate,
    required DateTime maturityDate,
    DateTime? asOf,
  }) {
    if (payoutType == PayoutType.payout) return principal;
    final f = progressFraction(openedDate: openedDate, maturityDate: maturityDate, asOf: asOf);
    final years = tenureYears(tenureMonths, tenureDays);
    return _cumulativeValue(
      principal: principal,
      ratePercent: ratePercent,
      periodsPerYear: periodsPerYear,
      years: years * f,
      shortTerm: years < shortTermYears,
    );
  }

  /// Typical premature-withdrawal penalty: most Indian banks charge 0.5%
  /// below the applicable rate on smaller deposits and 1% on ₹5 lakh and
  /// above. Only a starting point — the close-early dialog lets the user
  /// change it, or type in what the bank actually paid.
  static double defaultPrematurePenaltyPercent(double principal) => principal < 500000 ? 0.5 : 1.0;

  /// A closed-early payout, for both FD types: simple pro-rata interest for
  /// the time actually held at the booked rate minus [penaltyPercent],
  /// plus principal. Banks really apply the card rate for the period held
  /// (not the booked rate) minus the penalty — FixedWise doesn't know
  /// each bank's historical card rates, so this is an estimate.
  static double closedEarlyValue({
    required double principal,
    required double ratePercent,
    required DateTime openedDate,
    required DateTime closedDate,
    double penaltyPercent = 0,
  }) {
    final heldDays = daysBetween(openedDate, closedDate);
    final r = math.max(0.0, ratePercent - penaltyPercent) / 100;
    return principal + principal * r * (heldDays / 365);
  }

  /// Sampled points for Detail's growth chart: a rising curve for
  /// cumulative FDs (exact at both endpoints), or an explicit flat line at
  /// [FixedDeposit.principalAmount] for payout FDs — the mockup's rising
  /// sage curve only makes sense for a compounding FD, so a payout FD gets
  /// an honest flat line instead of reusing that visual.
  static List<ChartPoint> growthCurvePoints(FixedDeposit fd, {int sampleCount = 12}) {
    final points = <ChartPoint>[];
    final totalMs = fd.maturityDate.difference(fd.openedDate).inMilliseconds;
    for (var i = 0; i <= sampleCount; i++) {
      final date = fd.openedDate.add(Duration(milliseconds: (totalMs * i / sampleCount).round()));
      final value = accruedValueAt(
        principal: fd.principalAmount,
        ratePercent: fd.interestRatePercent,
        periodsPerYear: fd.compounding.periodsPerYear,
        tenureMonths: fd.tenureMonths,
        tenureDays: fd.tenureDays,
        payoutType: fd.payoutType,
        openedDate: fd.openedDate,
        maturityDate: fd.maturityDate,
        asOf: date,
      );
      points.add(ChartPoint(date, value));
    }
    return points;
  }

  /// `(Σ accrued value of active deposits − Σ principal) / Σ principal`,
  /// as a percentage — the dashboard's honest "overall growth since
  /// opening" figure. Payout FDs contribute nothing to the numerator
  /// (their accrued value is always their principal) since their interest
  /// is disbursed rather than retained in the deposit's own book value.
  /// `0` if there are no active deposits.
  static double overallGrowthPercent(List<FixedDeposit> activeDeposits, {DateTime? asOf}) {
    if (activeDeposits.isEmpty) return 0;
    var totalPrincipal = 0.0;
    var totalAccrued = 0.0;
    for (final fd in activeDeposits) {
      totalPrincipal += fd.principalAmount;
      totalAccrued += accruedValueAt(
        principal: fd.principalAmount,
        ratePercent: fd.interestRatePercent,
        periodsPerYear: fd.compounding.periodsPerYear,
        tenureMonths: fd.tenureMonths,
        tenureDays: fd.tenureDays,
        payoutType: fd.payoutType,
        openedDate: fd.openedDate,
        maturityDate: fd.maturityDate,
        asOf: asOf,
      );
    }
    if (totalPrincipal == 0) return 0;
    return (totalAccrued - totalPrincipal) / totalPrincipal * 100;
  }

  /// Active deposits, soonest-maturing first, capped at [count] — feeds
  /// both the dashboard's maturity-ladder bars and its "Maturing soon" list.
  static List<FixedDeposit> nextMaturingDeposits(List<FixedDeposit> deposits, {int count = 4}) {
    final active = deposits.where((fd) => fd.status == FdStatus.active).toList()
      ..sort((a, b) => a.maturityDate.compareTo(b.maturityDate));
    return active.take(count).toList();
  }

  // ---- FixedDeposit-based convenience wrappers ----

  static double maturityValue(FixedDeposit fd) => maturityValueRaw(
    principal: fd.principalAmount,
    ratePercent: fd.interestRatePercent,
    periodsPerYear: fd.compounding.periodsPerYear,
    tenureMonths: fd.tenureMonths,
    tenureDays: fd.tenureDays,
    payoutType: fd.payoutType,
  );

  static double interestEarned(FixedDeposit fd) => interestEarnedRaw(
    principal: fd.principalAmount,
    ratePercent: fd.interestRatePercent,
    periodsPerYear: fd.compounding.periodsPerYear,
    tenureMonths: fd.tenureMonths,
    tenureDays: fd.tenureDays,
    payoutType: fd.payoutType,
  );

  static double payoutPerPeriod(FixedDeposit fd) => payoutPerPeriodRaw(
    principal: fd.principalAmount,
    ratePercent: fd.interestRatePercent,
    periodsPerYear: fd.compounding.periodsPerYear,
  );

  static double fdProgressFraction(FixedDeposit fd, {DateTime? asOf}) =>
      progressFraction(openedDate: fd.openedDate, maturityDate: fd.maturityDate, asOf: asOf);

  static double fdAccruedValue(FixedDeposit fd, {DateTime? asOf}) => accruedValueAt(
    principal: fd.principalAmount,
    ratePercent: fd.interestRatePercent,
    periodsPerYear: fd.compounding.periodsPerYear,
    tenureMonths: fd.tenureMonths,
    tenureDays: fd.tenureDays,
    payoutType: fd.payoutType,
    openedDate: fd.openedDate,
    maturityDate: fd.maturityDate,
    asOf: asOf,
  );

  static double fdClosedEarlyValue(FixedDeposit fd, {required DateTime closedDate, double penaltyPercent = 0}) =>
      closedEarlyValue(
        principal: fd.principalAmount,
        ratePercent: fd.interestRatePercent,
        openedDate: fd.openedDate,
        closedDate: closedDate,
        penaltyPercent: penaltyPercent,
      );
}
