import 'package:fixedwise_app/features/deposits/domain/compounding_frequency.dart';
import 'package:fixedwise_app/features/deposits/domain/fd_status.dart';
import 'package:fixedwise_app/features/deposits/domain/fixed_deposit.dart';
import 'package:fixedwise_app/features/deposits/domain/payout_type.dart';
import 'package:flutter_test/flutter_test.dart';

FixedDeposit _fd({
  required DateTime openedDate,
  required int tenureMonths,
  FdStatus status = FdStatus.active,
}) {
  final now = DateTime.now();
  return FixedDeposit(
    id: 'fd-1',
    holderId: 'holder-1',
    bankName: 'Test Bank',
    interestRatePercent: 7,
    principalAmount: 10000,
    openedDate: openedDate,
    tenureMonths: tenureMonths,
    compounding: CompoundingFrequency.quarterly,
    payoutType: PayoutType.cumulative,
    autoRenew: false,
    status: status,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('FixedDeposit.cardStatusAsOf', () {
    test('active with plenty of runway is FdCardStatus.active', () {
      final fd = _fd(openedDate: DateTime(2025, 1, 1), tenureMonths: 24);
      // Maturity is 2027-01-01 — asOf is months away, well outside the
      // 7-day maturing-soon window.
      expect(fd.cardStatusAsOf(DateTime(2026, 1, 1)), FdCardStatus.active);
    });

    test('active within the maturing-soon window is FdCardStatus.maturingSoon', () {
      final fd = _fd(openedDate: DateTime(2025, 1, 1), tenureMonths: 12);
      // Maturity is 2026-01-01.
      // 7 days out, exactly at the window's inclusive edge.
      expect(fd.cardStatusAsOf(DateTime(2025, 12, 25)), FdCardStatus.maturingSoon);
      expect(fd.cardStatusAsOf(DateTime(2025, 12, 28)), FdCardStatus.maturingSoon);
      // 8 days out — just outside the window.
      expect(fd.cardStatusAsOf(DateTime(2025, 12, 24)), FdCardStatus.active);
    });

    test('active past its own maturity date (not yet renewed/closed) is FdCardStatus.done', () {
      final fd = _fd(openedDate: DateTime(2025, 1, 1), tenureMonths: 12);
      expect(fd.cardStatusAsOf(DateTime(2026, 1, 2)), FdCardStatus.done);
    });

    test('closedEarly and matured are both FdCardStatus.done regardless of date', () {
      final closedEarly = _fd(openedDate: DateTime(2025, 1, 1), tenureMonths: 24, status: FdStatus.closedEarly);
      final matured = _fd(openedDate: DateTime(2025, 1, 1), tenureMonths: 24, status: FdStatus.matured);
      expect(closedEarly.cardStatusAsOf(DateTime(2025, 6, 1)), FdCardStatus.done);
      expect(matured.cardStatusAsOf(DateTime(2025, 6, 1)), FdCardStatus.done);
    });
  });

  group('FixedDeposit.isClosed', () {
    test('true only for closedEarly/matured, not for a quietly-past-due active deposit', () {
      expect(_fd(openedDate: DateTime(2020, 1, 1), tenureMonths: 1).isClosed, isFalse);
      expect(_fd(openedDate: DateTime(2020, 1, 1), tenureMonths: 1, status: FdStatus.closedEarly).isClosed, isTrue);
      expect(_fd(openedDate: DateTime(2020, 1, 1), tenureMonths: 1, status: FdStatus.matured).isClosed, isTrue);
    });
  });

  group('FdStatus.fromStorageKey', () {
    test('round-trips the new matured status', () {
      expect(FdStatus.fromStorageKey('matured'), FdStatus.matured);
      expect(FdStatus.matured.storageKey, 'matured');
    });
  });

  group('addTenure / maturity dates', () {
    test('a month-end start clamps to the target month\'s last day', () {
      expect(addTenure(DateTime(2026, 1, 31), months: 1), DateTime(2026, 2, 28));
      expect(addTenure(DateTime(2028, 1, 31), months: 1), DateTime(2028, 2, 29));
      expect(addTenure(DateTime(2026, 8, 31), months: 1), DateTime(2026, 9, 30));
    });

    test('extra days are added after the months', () {
      expect(addTenure(DateTime(2026, 1, 1), months: 12, days: 15), DateTime(2027, 1, 16));
      expect(addTenure(DateTime(2026, 1, 1), months: 0, days: 444), DateTime(2027, 3, 21));
    });

    test('describeTenure reads like a bank quote', () {
      expect(describeTenure(27, 0), '2 years 3 months');
      expect(describeTenure(0, 444), '444 days');
      expect(describeTenure(12, 15), '1 year 15 days');
      expect(describeTenure(1, 1), '1 month 1 day');
    });

    test('records saved before tenureDays/isTaxSaver/nominee existed still load', () {
      final legacy = _fd(openedDate: DateTime(2026, 1, 1), tenureMonths: 12).toMap()
        ..remove('tenureDays')
        ..remove('isTaxSaver')
        ..remove('nomineeName');
      final restored = FixedDeposit.fromMap(legacy);
      expect(restored.tenureDays, 0);
      expect(restored.isTaxSaver, isFalse);
      expect(restored.nomineeName, isNull);
    });
  });
}
