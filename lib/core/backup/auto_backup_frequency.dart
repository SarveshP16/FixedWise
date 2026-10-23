/// How often FixedWise should silently write a backup into the user's
/// chosen backup folder, checked once at every app launch (see
/// `auto_backup.dart`) rather than via a true OS-level background
/// schedule. The actual due-date math lives in `nextAutoBackupDueDate`.
enum AutoBackupFrequency {
  off(storageKey: 'off', label: 'Off'),
  daily(storageKey: 'daily', label: 'Daily'),
  weekly(storageKey: 'weekly', label: 'Weekly'),
  monthly(storageKey: 'monthly', label: 'Monthly');

  const AutoBackupFrequency({required this.storageKey, required this.label});

  final String storageKey;
  final String label;

  static AutoBackupFrequency fromStorageKey(String key) {
    return AutoBackupFrequency.values.firstWhere((value) => value.storageKey == key, orElse: () => AutoBackupFrequency.off);
  }
}
