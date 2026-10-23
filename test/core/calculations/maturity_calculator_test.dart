import 'package:fixedwise_app/core/calculations/maturity_calculator.dart';
import 'package:fixedwise_app/features/deposits/domain/compounding_frequency.dart';
import 'package:fixedwise_app/features/deposits/domain/fd_status.dart';
import 'package:fixedwise_app/features/deposits/domain/fixed_deposit.dart';
import 'package:fixedwise_app/features/deposits/domain/payout_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MaturityCalculator.maturityValueRaw / interestEarnedRaw', () {
    test('reproduces the mockup calculator script exactly for its own default inputs', () {
      // The mockup's script (fd-manager-mockup.html) computes:
      //   maturity = principal * Math.pow(1 + rate/n, n*years)
      // with rate=0.074, n=4, principal=10000, months=24 (years=2). Running
      // that formula (verified with `Math.pow`/`dart:math`'s `pow`, which
      // agree bit-for-bit here) gives ~$11,579.46 / ~$1,579.46 — NOT the
      // "$12,140" / "$2,140" the mockup's *static* HTML placeholder text
      // shows, which is inconsistent with its own live script (the script
      // runs `recalc()` on load and would overwrite that placeholder). This
      // test pins our Dart port to the formula's actual output, which is
      // the thing that must be faithfully reproduced.
      final maturity = MaturityCalculator.maturityValueRaw(
        principal: 10000,
        ratePercent: 7.4,
        periodsPerYear: 4,
        tenureMonths: 24,
        payoutType: PayoutType.cumulative,
      );
      final interest = MaturityCalculator.interestEarnedRaw(
        principal: 10000,
        ratePercent: 7.4,
        periodsPerYear: 4,
        tenureMonths: 24,
        payoutType: PayoutType.cumulative,
      );

      expect(maturity, closeTo(11579.46, 0.01));
      expect(interest, closeTo(1579.46, 0.01));
    });

    test('payout FD returns principal as maturity value and simple interest as earned', () {
      final maturity = MaturityCalculator.maturityValueRaw(
        principal: 10000,
        ratePercent: 7.4,
        periodsPerYear: 4,
        tenureMonths: 24,
        payoutType: PayoutType.payout,
      );
      final interest = MaturityCalculator.interestEarnedRaw(
        principal: 10000,
        ratePercent: 7.4,
        periodsPerYear: 4,
        tenureMonths: 24,
        payoutType: PayoutType.payout,
      );

      expect(maturity, 10000);
      // Simple interest: P * r * t = 10000 * 0.074 * 2 = 1480.
      expect(interest, closeTo(1480, 0.01));
    });
  });

  group('Indian bank conventions', () {
    test('a broken period earns simple interest on the compounded amount', () {
      // 13 months quarterly: 4 full quarters compounded, then 1 month simple.
      final maturity = MaturityCalculator.maturityValueRaw(
        principal: 100000,
        ratePercent: 7,
        periodsPerYear: 4,
        tenureMonths: 13,
        payoutType: PayoutType.cumulative,
      );
      final afterFourQuarters = 100000 * 1.0175 * 1.0175 * 1.0175 * 1.0175;
      expect(maturity, closeTo(afterFourQuarters * (1 + 0.07 / 12), 0.01));
    });

    test('extra days count as a broken period too', () {
      // 1 year 15 days quarterly.
      final maturity = MaturityCalculator.maturityValueRaw(
        principal: 100000,
        ratePercent: 7,
        periodsPerYear: 4,
        tenureMonths: 12,
        tenureDays: 15,
        payoutType: PayoutType.cumulative,
      );
      final afterFourQuarters = 100000 * 1.0175 * 1.0175 * 1.0175 * 1.0175;
      expect(maturity, closeTo(afterFourQuarters * (1 + 0.07 * 15 / 365), 0.01));
    });

    test('under six months is plain simple interest', () {
      final maturity = MaturityCalculator.maturityValueRaw(
        principal: 100000,
        ratePercent: 6,
        periodsPerYear: 4,
        tenureMonths: 0,
        tenureDays: 91,
        payoutType: PayoutType.cumulative,
      );
      expect(maturity, closeTo(100000 * (1 + 0.06 * 91 / 365), 0.01));
    });

    test('half-yearly compounding', () {
      final maturity = MaturityCalculator.maturityValueRaw(
        principal: 100000,
        ratePercent: 8,
        periodsPerYear: 2,
        tenureMonths: 24,
        payoutType: PayoutType.cumulative,
      );
      expect(maturity, closeTo(100000 * 1.04 * 1.04 * 1.04 * 1.04, 0.01));
    });

    test('accrued value at maturity still equals the maturity value for a broken tenure', () {
      final opened = DateTime(2026, 1, 1);
      final matures = addTenure(opened, months: 13, days: 10);
      final atEnd = MaturityCalculator.accruedValueAt(
        principal: 100000,
        ratePercent: 7,
        periodsPerYear: 4,
        tenureMonths: 13,
        tenureDays: 10,
        payoutType: PayoutType.cumulative,
        openedDate: opened,
        maturityDate: matures,
        asOf: matures,
      );
      final maturity = MaturityCalculator.maturityValueRaw(
        principal: 100000,
        ratePercent: 7,
        periodsPerYear: 4,
        tenureMonths: 13,
        tenureDays: 10,
        payoutType: PayoutType.cumulative,
      );
      expect(atEnd, closeTo(maturity, 0.01));
    });
  });

  group('MaturityCalculator.payoutPerPeriodRaw', () {
    test('splits annual interest evenly across periods', () {
      final perPeriod = MaturityCalculator.payoutPerPeriodRaw(principal: 10000, ratePercent: 7.4, periodsPerYear: 4);
      // 10000 * 0.074 / 4 = 185.
      expect(perPeriod, closeTo(185, 0.001));
    });
  });

  group('MaturityCalculator.progressFraction', () {
    test('is 0 at the start, 1 at maturity, and clamps outside that range', () {
      final opened = DateTime(2026, 1, 1);
      final matures = DateTime(2027, 1, 1);

      expect(MaturityCalculator.progressFraction(openedDate: opened, maturityDate: matures, asOf: opened), 0);
      expect(MaturityCalculator.progressFraction(openedDate: opened, maturityDate: matures, asOf: matures), 1);
      expect(
        MaturityCalculator.progressFraction(
          openedDate: opened,
          maturityDate: matures,
          asOf: DateTime(2028, 1, 1),
        ),
        1,
      );
    });
  });

  group('MaturityCalculator.accruedValueAt', () {
    test('cumulative FD is exactly principal at f=0 and maturity value at f=1', () {
      final opened = DateTime(2026, 1, 1);
      final matures = DateTime(2028, 1, 1); // 24 months later

      final atStart = MaturityCalculator.accruedValueAt(
        principal: 10000,
        ratePercent: 7.4,
        periodsPerYear: 4,
        tenureMonths: 24,
        payoutType: PayoutType.cumulative,
        openedDate: opened,
        maturityDate: matures,
        asOf: opened,
      );
      final atEnd = MaturityCalculator.accruedValueAt(
        principal: 10000,
        ratePercent: 7.4,
        periodsPerYear: 4,
        tenureMonths: 24,
        payoutType: PayoutType.cumulative,
        openedDate: opened,
        maturityDate: matures,
        asOf: matures,
      );

      expect(atStart, closeTo(10000, 0.01));
      expect(atEnd, closeTo(11579.46, 0.01));
    });

    test('payout FD stays flat at principal throughout the term', () {
      final opened = DateTime(2026, 1, 1);
      final matures = DateTime(2028, 1, 1);
      final midway = DateTime(2027, 1, 1);

      final value = MaturityCalculator.accruedValueAt(
        principal: 10000,
        ratePercent: 7.4,
        periodsPerYear: 4,
        tenureMonths: 24,
        payoutType: PayoutType.payout,
        openedDate: opened,
        maturityDate: matures,
        asOf: midway,
      );

      expect(value, 10000);
    });
  });

  group('MaturityCalculator.closedEarlyValue', () {
    test('adds simple pro-rata interest for the time actually held', () {
      final opened = DateTime(2026, 1, 1);
      final closed = DateTime(2027, 1, 1); // exactly 365 days later

      final value = MaturityCalculator.closedEarlyValue(
        principal: 10000,
        ratePercent: 7.4,
        openedDate: opened,
        closedDate: closed,
      );

      // 10000 + 10000 * 0.074 * (365/365) = 10740
      expect(value, closeTo(10740, 0.01));
    });

    test('takes the premature-withdrawal penalty off the rate', () {
      final value = MaturityCalculator.closedEarlyValue(
        principal: 10000,
        ratePercent: 7.4,
        openedDate: DateTime(2026, 1, 1),
        closedDate: DateTime(2027, 1, 1),
        penaltyPercent: 1,
      );

      // 10000 + 10000 * 0.064 = 10640
      expect(value, closeTo(10640, 0.01));
    });

    test('default penalty is 0.5% below ₹5 lakh and 1% from ₹5 lakh up', () {
      expect(MaturityCalculator.defaultPrematurePenaltyPercent(499999), 0.5);
      expect(MaturityCalculator.defaultPrematurePenaltyPercent(500000), 1.0);
    });
  });

  group('MaturityCalculator.overallGrowthPercent', () {
    test('is 0 with no active deposits', () {
      expect(MaturityCalculator.overallGrowthPercent([]), 0);
    });

    test('reflects unrealized growth of active cumulative deposits only', () {
      final opened = DateTime(2026, 1, 1);
      final matures = DateTime(2028, 1, 1);
      final fd = _fd(
        principal: 10000,
        ratePercent: 7.4,
        periodsPerYear: 4,
        tenureMonths: 24,
        payoutType: PayoutType.cumulative,
        openedDate: opened,
      );

      final growth = MaturityCalculator.overallGrowthPercent([fd], asOf: matures);

      // (11579.46 - 10000) / 10000 * 100 ≈ 15.79%
      expect(growth, closeTo(15.79, 0.01));
    });
  });

  group('MaturityCalculator.nextMaturingDeposits', () {
    test('sorts active deposits by soonest maturity and excludes closed ones', () {
      final soon = _fd(
        principal: 1000,
        ratePercent: 5,
        periodsPerYear: 4,
        tenureMonths: 6,
        payoutType: PayoutType.cumulative,
        openedDate: DateTime(2026, 1, 1),
      );
      final later = _fd(
        principal: 1000,
        ratePercent: 5,
        periodsPerYear: 4,
        tenureMonths: 24,
        payoutType: PayoutType.cumulative,
        openedDate: DateTime(2026, 1, 1),
      );
      final closed = _fd(
        principal: 1000,
        ratePercent: 5,
        periodsPerYear: 4,
        tenureMonths: 3,
        payoutType: PayoutType.cumulative,
        openedDate: DateTime(2026, 1, 1),
        status: FdStatus.closedEarly,
      );

      final result = MaturityCalculator.nextMaturingDeposits([later, closed, soon]);

      expect(result, [soon, later]);
    });
  });
}

FixedDeposit _fd({
  required double principal,
  required double ratePercent,
  required int periodsPerYear,
  required int tenureMonths,
  required PayoutType payoutType,
  required DateTime openedDate,
  FdStatus status = FdStatus.active,
}) {
  final compounding = CompoundingFrequency.values.firstWhere((c) => c.periodsPerYear == periodsPerYear);
  return FixedDeposit(
    id: 'test-${openedDate.microsecondsSinceEpoch}-$tenureMonths',
    holderId: 'self',
    bankName: 'Test Bank',
    interestRatePercent: ratePercent,
    principalAmount: principal,
    openedDate: openedDate,
    tenureMonths: tenureMonths,
    compounding: compounding,
    payoutType: payoutType,
    autoRenew: false,
    status: status,
    createdAt: openedDate,
    updatedAt: openedDate,
  );
}
