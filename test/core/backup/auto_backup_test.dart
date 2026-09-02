import 'package:fixedwise_app/core/backup/auto_backup.dart';
import 'package:fixedwise_app/core/backup/auto_backup_frequency.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('nextAutoBackupDueDate', () {
    test('weekly is a fixed 7 days later', () {
      final due = nextAutoBackupDueDate(DateTime(2026, 3, 10), AutoBackupFrequency.weekly);
      expect(due, DateTime(2026, 3, 17));
    });

    test('monthly lands on the same day next month, not +30 days', () {
      // January has 31 days — a naive `Duration(days: 30)` would land on
      // Mar 2, not Feb 28, and would drift further every month after that.
      final due = nextAutoBackupDueDate(DateTime(2026, 1, 28), AutoBackupFrequency.monthly);
      expect(due, DateTime(2026, 2, 28));
    });

    test('monthly normalizes a day-of-month that overflows the next month', () {
      // Dart's DateTime constructor rolls Feb 31 forward into March —
      // documented behavior, not something this function needs to work
      // around (matches FixedDeposit.maturityDate's own accepted
      // simplification).
      final due = nextAutoBackupDueDate(DateTime(2026, 1, 31), AutoBackupFrequency.monthly);
      expect(due, DateTime(2026, 3, 3));
    });
  });
}
