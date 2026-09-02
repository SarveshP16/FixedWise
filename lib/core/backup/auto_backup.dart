import 'package:flutter/foundation.dart';

import '../../features/profile/data/settings_repository.dart';
import 'auto_backup_frequency.dart';
import 'google_drive_backup_service.dart';

/// When a deposit last backed up at [lastBackupAt] under [frequency] is
/// next due. Weekly is a fixed 7-day span; monthly is calendar-field
/// arithmetic (`DateTime(year, month + 1, day)`) rather than a fixed
/// 30-day approximation — same "never do raw Duration day-math across a
/// month" rule the FD maturity-date calculations follow, since Dart
/// normalizes calendar-field overflow exactly regardless of month length
/// or DST, where fixed-day-count math would drift.
DateTime nextAutoBackupDueDate(DateTime lastBackupAt, AutoBackupFrequency frequency) {
  return switch (frequency) {
    AutoBackupFrequency.weekly => DateTime(lastBackupAt.year, lastBackupAt.month, lastBackupAt.day + 7),
    AutoBackupFrequency.monthly => DateTime(lastBackupAt.year, lastBackupAt.month + 1, lastBackupAt.day),
    AutoBackupFrequency.off => DateTime(9999), // unreachable — callers check for `off` first.
  };
}

/// Checked once at every app launch (see `main.dart`) — FixedWise has no
/// true background scheduler (a deliberate MVP trade-off: a real
/// WorkManager/BGTaskScheduler job would run even while the app is
/// closed, at the cost of a new plugin and native background-task
/// registration on both platforms that's hard to verify actually fires
/// reliably from this dev environment). Instead, "weekly"/"monthly" means
/// "next time you open the app on or after the due date" — if you don't
/// open FixedWise for a month, a weekly backup simply catches up then,
/// rather than having silently run four times in the background.
///
/// Runs fully silently per the user's choice: no snackbar, no
/// notification, on success or failure — `Profile`'s "Last backup"
/// timestamp is the only visible record. A failure (not signed in,
/// network down, stale authorization) is swallowed and simply retried
/// next launch, never surfaced as an interruption.
Future<void> runAutoBackupIfDue() async {
  final settings = SettingsRepository.openDefault();
  final frequency = settings.getAutoBackupFrequency();
  if (frequency == AutoBackupFrequency.off) return;
  if (settings.getGoogleDriveConnectedEmail() == null) return;

  final lastBackupAt = settings.getLastGoogleDriveBackupAt();
  final now = DateTime.now();
  if (lastBackupAt != null && now.isBefore(nextAutoBackupDueDate(lastBackupAt, frequency))) return;

  try {
    // `interactive: false` — this runs unprompted at launch; a stale
    // authorization should make this attempt fail (and quietly retry
    // next launch), never pop up a sign-in screen the user didn't ask for.
    await GoogleDriveBackupService.instance.backup(interactive: false);
    await settings.setLastGoogleDriveBackupAt(now);
  } catch (error, stackTrace) {
    debugPrint('Auto-backup skipped: $error\n$stackTrace');
  }
}
