import 'package:fixedwise_app/core/calculations/india_tax.dart';
import 'package:fixedwise_app/features/deposits/domain/compounding_frequency.dart';
import 'package:fixedwise_app/features/deposits/domain/fd_status.dart';
import 'package:fixedwise_app/features/deposits/domain/fixed_deposit.dart';
import 'package:fixedwise_app/features/deposits/domain/payout_type.dart';
import 'package:fixedwise_app/features/holders/domain/holder.dart';
import 'package:flutter_test/flutter_test.dart';

FixedDeposit _fd({
  String id = 'fd',
  String holderId = 'self',
  String bankName = 'SBI',
  double principal = 100000,
  double rate = 7,
  required DateTime opened,
  int months = 12,
  PayoutType payoutType = PayoutType.payout,
  FdStatus status = FdStatus.active,
  DateTime? closedDate,
  double? closedValue,
}) {
  return FixedDeposit(
    id: id,
    holderId: holderId,
    bankName: bankName,
    interestRatePercent: rate,
    principalAmount: principal,
    openedDate: opened,
    tenureMonths: months,
    compounding: CompoundingFrequency.quarterly,
    payoutType: payoutType,
    autoRenew: false,
    status: status,
    closedDate: closedDate,
    closedValue: closedValue,
    createdAt: opened,
    updatedAt: opened,
  );
}

final _self = Holder(id: 'self', name: 'Me', isSelf: true, createdAt: DateTime(2020));
final _parent = Holder(id: 'parent', name: 'Mum', isSelf: false, createdAt: DateTime(2021), isSeniorCitizen: true);

void main() {
  group('FinancialYear', () {
    test('runs April to March', () {
      expect(FinancialYear.containing(DateTime(2026, 3, 31)).startYear, 2025);
      expect(FinancialYear.containing(DateTime(2026, 4, 1)).startYear, 2026);
      expect(const FinancialYear(2025).label, 'FY 2025-26');
      expect(const FinancialYear(2099).label, 'FY 2099-00');
    });
  });

  group('tdsThresholdFor', () {
    test('uses the Budget 2025 limits from FY 2025-26', () {
      expect(tdsThresholdFor(const FinancialYear(2025), seniorCitizen: false), 50000);
      expect(tdsThresholdFor(const FinancialYear(2025), seniorCitizen: true), 100000);
      expect(tdsThresholdFor(const FinancialYear(2024), seniorCitizen: false), 40000);
      expect(tdsThresholdFor(const FinancialYear(2024), seniorCitizen: true), 50000);
    });
  });

  group('interestAccruedBetween', () {
    test('splits a payout FD across financial years by days', () {
      final fd = _fd(opened: DateTime(2025, 10, 1), months: 12);
      final fy25 = const FinancialYear(2025);
      final fy26 = const FinancialYear(2026);
      final inFy25 = interestAccruedBetween(fd, fy25.start, fy25.end);
      final inFy26 = interestAccruedBetween(fd, fy26.start, fy26.end);
      // 1 Oct 2025 → 1 Apr 2026 is 182 days; the rest of the year is 183.
      expect(inFy25, closeTo(100000 * 0.07 * 182 / 365, 0.01));
      expect(inFy26, closeTo(100000 * 0.07 * 183 / 365, 0.01));
    });

    test('a cumulative FD accrues its full interest across its term', () {
      final fd = _fd(opened: DateTime(2025, 4, 1), months: 24, payoutType: PayoutType.cumulative);
      final total = [2025, 2026].fold(
        0.0,
        (sum, year) => sum + interestAccruedBetween(fd, FinancialYear(year).start, FinancialYear(year).end),
      );
      expect(total, closeTo(100000 * 1.0175 * 1.0175 * 1.0175 * 1.0175 * 1.0175 * 1.0175 * 1.0175 * 1.0175 - 100000, 0.5));
    });

    test('an FD closed early only counts the interest it actually paid', () {
      final fd = _fd(
        opened: DateTime(2025, 4, 1),
        months: 24,
        status: FdStatus.closedEarly,
        closedDate: DateTime(2025, 10, 1),
        closedValue: 103000,
      );
      final year = const FinancialYear(2025);
      expect(interestAccruedBetween(fd, year.start, year.end), closeTo(3000, 0.01));
    });
  });

  group('summariseByHolderAndBank', () {
    test('flags TDS per holder per bank, using the senior-citizen threshold', () {
      final summaries = summariseByHolderAndBank(
        deposits: [
          _fd(id: 'a', principal: 800000, opened: DateTime(2025, 4, 1)),
          _fd(id: 'b', holderId: 'parent', principal: 800000, opened: DateTime(2025, 4, 1)),
        ],
        holders: [_self, _parent],
        year: const FinancialYear(2025),
        asOf: DateTime(2025, 6, 1),
      );
      // ₹56,000 of interest each: over ₹50,000 for Me, under ₹1 lakh for Mum.
      expect(summaries.map((s) => s.holder.name), ['Me', 'Mum']);
      expect(summaries[0].tdsLikely, isTrue);
      expect(summaries[0].estimatedTds, closeTo(5600, 0.5));
      expect(summaries[1].tdsLikely, isFalse);
    });

    test('groups bank names ignoring case and spaces, and checks DICGC cover', () {
      final summaries = summariseByHolderAndBank(
        deposits: [
          _fd(id: 'a', bankName: 'HDFC Bank', principal: 300000, opened: DateTime(2025, 4, 1)),
          _fd(id: 'b', bankName: ' hdfc bank ', principal: 250000, opened: DateTime(2025, 4, 1)),
        ],
        holders: [_self],
        year: const FinancialYear(2025),
        asOf: DateTime(2025, 4, 1),
      );
      expect(summaries, hasLength(1));
      expect(summaries.single.insuredExposure, closeTo(550000, 0.01));
      expect(summaries.single.exceedsDicgcCover, isTrue);
    });
  });
}
