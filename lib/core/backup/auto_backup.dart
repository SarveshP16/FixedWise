import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../features/profile/data/settings_repository.dart';
import 'auto_backup_frequency.dart';
import 'backup_folder_service.dart';
import 'backup_models.dart';

/// Automatic backups are named with this prefix so pruning only ever
/// touches files FixedWise wrote on its own — a manual "Export to a file"
/// (`fixedwise-backup-…`) saved into the same folder is never deleted.
const autoBackupFilePrefix = 'fixedwise-auto-';

/// How many automatic backups to keep in the folder — enough to step back
/// past a bad edit that went unnoticed for a few backup cycles, without
/// the folder growing forever.
const autoBackupsToKeep = 5;

/// When a deposit last backed up at [lastBackupAt] under [frequency] is
/// next due. Daily/weekly are fixed spans; monthly is calendar-field
/// arithmetic (`DateTime(year, month + 1, day)`) rather than a fixed
/// 30-day approximation — same "never do raw Duration day-math across a
/// month" rule the FD maturity-date calculations follow, since Dart
/// normalizes calendar-field overflow exactly regardless of month length
/// or DST, where fixed-day-count math would drift.
DateTime nextAutoBackupDueDate(DateTime lastBackupAt, AutoBackupFrequency frequency) {
  return switch (frequency) {
    AutoBackupFrequency.daily => DateTime(lastBackupAt.year, lastBackupAt.month, lastBackupAt.day + 1),
    AutoBackupFrequency.weekly => DateTime(lastBackupAt.year, lastBackupAt.month, lastBackupAt.day + 7),
    AutoBackupFrequency.monthly => DateTime(lastBackupAt.year, lastBackupAt.month + 1, lastBackupAt.day),
    AutoBackupFrequency.off => DateTime(9999), // unreachable — callers check for `off` first.
  };
}

/// File name for an automatic backup taken at [at]. Sorts
/// chronologically as plain text, which is what [pruneOldAutoBackups]
/// relies on.
String autoBackupFileName(DateTime at) => '$autoBackupFilePrefix${DateFormat('yyyy-MM-dd-HHmmss').format(at)}.json';

/// The automatic backups in [files] beyond the newest [keep] — the ones
/// to delete.
List<BackupFolderFile> autoBackupsToPrune(List<BackupFolderFile> files, {int keep = autoBackupsToKeep}) {
  final autoBackups = files.where((file) => file.name.startsWith(autoBackupFilePrefix)).toList()
    ..sort((a, b) => b.name.compareTo(a.name));
  return autoBackups.skip(keep).toList();
}

/// Writes one backup into the chosen folder right now, then prunes old
/// automatic ones. Throws if no folder is set or access was revoked.
Future<DateTime> backUpToFolderNow({SettingsRepository? settings}) async {
  final repository = settings ?? SettingsRepository.openDefault();
  final treeUri = repository.getBackupFolderUri();
  if (treeUri == null) throw StateError('No backup folder chosen yet');

  final folders = BackupFolderService.instance;
  if (!await folders.hasAccess(treeUri)) {
    throw StateError('FixedWise lost access to the backup folder — choose it again');
  }

  final now = DateTime.now();
  await folders.writeText(treeUri, autoBackupFileName(now), buildExportJson());
  await repository.setLastAutoBackupAt(now);

  for (final stale in autoBackupsToPrune(await folders.listFiles(treeUri))) {
    await folders.delete(stale.uri);
  }
  return now;
}

/// Checked once at every app launch (see `main.dart`) — FixedWise has no
/// true background scheduler (a deliberate trade-off: a real WorkManager
/// job would need another plugin and native background-task registration
/// for a once-a-week JSON write). Instead, "weekly"/"monthly" means "next
/// time you open the app on or after the due date" — if you don't open
/// FixedWise for a month, a weekly backup simply catches up then.
///
/// Runs fully silently: no snackbar or notification on success or
/// failure — Profile's "Last backup" timestamp is the visible record. A
/// failure (folder removed, access revoked) is swallowed and retried next
/// launch.
///
/// Separately from this, Android's own Auto Backup (configured in
/// `AndroidManifest.xml`) copies the app's data to the user's Google
/// account, when they have device backup turned on.
Future<void> runAutoBackupIfDue() async {
  final settings = SettingsRepository.openDefault();
  final frequency = settings.getAutoBackupFrequency();
  if (frequency == AutoBackupFrequency.off) return;
  if (settings.getBackupFolderUri() == null) return;

  final lastBackupAt = settings.getLastAutoBackupAt();
  if (lastBackupAt != null && DateTime.now().isBefore(nextAutoBackupDueDate(lastBackupAt, frequency))) return;

  try {
    await backUpToFolderNow(settings: settings);
  } catch (error, stackTrace) {
    debugPrint('Auto-backup skipped: $error\n$stackTrace');
  }
}
