/// How often FixedWise should silently back up to Google Drive on its
/// own, checked once at every app launch (see `auto_backup.dart`) rather
/// than via a true OS-level background schedule — see the implementation
/// plan for why that trade-off was chosen. The actual due-date math for
/// `weekly`/`monthly` lives in `nextAutoBackupDueDate`, not here.
enum AutoBackupFrequency {
  off(storageKey: 'off', label: 'Off'),
  weekly(storageKey: 'weekly', label: 'Weekly'),
  monthly(storageKey: 'monthly', label: 'Monthly');

  const AutoBackupFrequency({required this.storageKey, required this.label});

  final String storageKey;
  final String label;

  static AutoBackupFrequency fromStorageKey(String key) {
    return AutoBackupFrequency.values.firstWhere((value) => value.storageKey == key, orElse: () => AutoBackupFrequency.off);
  }
}
