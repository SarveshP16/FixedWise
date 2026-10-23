import 'package:fixedwise_app/core/backup/auto_backup.dart';
import 'package:fixedwise_app/core/backup/auto_backup_frequency.dart';
import 'package:fixedwise_app/core/backup/backup_folder_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('nextAutoBackupDueDate', () {
    test('daily is the next calendar day', () {
      expect(nextAutoBackupDueDate(DateTime(2026, 3, 31, 22), AutoBackupFrequency.daily), DateTime(2026, 4, 1));
    });

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

  group('automatic backup files', () {
    BackupFolderFile file(String name) => BackupFolderFile(uri: 'content://$name', name: name, lastModified: DateTime(2026));

    test('names sort chronologically', () {
      final earlier = autoBackupFileName(DateTime(2026, 1, 9, 23, 59, 59));
      final later = autoBackupFileName(DateTime(2026, 1, 10, 0, 0, 1));
      expect(earlier.compareTo(later), lessThan(0));
      expect(earlier, 'fixedwise-auto-2026-01-09-235959.json');
    });

    test('pruning keeps the newest automatic backups and never touches manual exports', () {
      final files = [
        for (var day = 1; day <= 7; day++) file(autoBackupFileName(DateTime(2026, 1, day))),
        file('fixedwise-backup-2025-12-01.json'),
        file('notes.txt'),
      ];
      final pruned = autoBackupsToPrune(files, keep: 5).map((f) => f.name);
      expect(pruned, [autoBackupFileName(DateTime(2026, 1, 2)), autoBackupFileName(DateTime(2026, 1, 1))]);
    });
  });
}
