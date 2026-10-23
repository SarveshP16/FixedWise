import 'package:hive/hive.dart';

import '../../../core/backup/auto_backup_frequency.dart';
import '../../../core/storage/hive_boxes.dart';
import '../../../core/theme/theme_preference.dart';

/// Reads/writes simple app-wide preferences — a plain key-value Hive box,
/// not per-record like the holders/deposits boxes, since there's only a
/// handful of scalar settings.
class SettingsRepository {
  SettingsRepository(this._box);

  final Box _box;

  static const _displayNameKey = 'displayName';
  static const _notificationLeadDaysKey = 'notificationLeadDays';
  static const _backupFolderUriKey = 'backupFolderUri';
  static const _backupFolderNameKey = 'backupFolderName';
  static const _notificationPermissionsRequestedKey = 'notificationPermissionsRequested';
  static const _autoBackupFrequencyKey = 'autoBackupFrequency';
  static const _lastAutoBackupAtKey = 'lastAutoBackupAt';
  static const _biometricUnlockEnabledKey = 'biometricUnlockEnabled';
  static const _themePreferenceKey = 'themePreference';

  /// Keys left behind by features that no longer exist (Google Drive
  /// backup, the ads/"Remove ads" purchase) — deleted once at startup by
  /// [removeLegacyKeys] so they don't linger in exports forever.
  static const _legacyKeys = ['googleDriveConnectedEmail', 'lastGoogleDriveBackupAt', 'adsRemoved'];

  /// Settings that only make sense on the device that wrote them — a
  /// backup-folder grant belongs to this install, and permission prompts
  /// should be asked again on a new phone. Left out of every export (see
  /// `buildExportJson`) and never overwritten by a restore.
  static const deviceOnlyKeys = {
    _backupFolderUriKey,
    _backupFolderNameKey,
    _lastAutoBackupAtKey,
    _notificationPermissionsRequestedKey,
    _biometricUnlockEnabledKey,
  };

  static const defaultNotificationLeadDays = 7;

  String? getDisplayName() => _box.get(_displayNameKey) as String?;

  Future<void> setDisplayName(String value) => _box.put(_displayNameKey, value);

  int getNotificationLeadDays() => (_box.get(_notificationLeadDaysKey) as int?) ?? defaultNotificationLeadDays;

  Future<void> setNotificationLeadDays(int value) => _box.put(_notificationLeadDaysKey, value);

  /// The Storage Access Framework tree URI of the folder automatic
  /// backups go to — see `BackupFolderService`. `null` until chosen.
  String? getBackupFolderUri() => _box.get(_backupFolderUriKey) as String?;

  /// The chosen backup folder's display name, for Profile.
  String? getBackupFolderName() => _box.get(_backupFolderNameKey) as String?;

  Future<void> setBackupFolder({required String? uri, String? name}) async {
    if (uri == null) {
      await _box.deleteAll([_backupFolderUriKey, _backupFolderNameKey]);
    } else {
      await _box.putAll({_backupFolderUriKey: uri, _backupFolderNameKey: name});
    }
  }

  /// Whether we've already asked the OS for notification/exact-alarm
  /// permissions once. Android's "Alarms & reminders" grant is a full-
  /// screen Settings deep-link, not an in-app dialog — asking again on
  /// every single app launch until the user grants it is a bad enough
  /// experience that it's worth asking only once, ever, regardless of
  /// the outcome (the user can still turn it on later from OS Settings).
  bool getNotificationPermissionsRequested() => (_box.get(_notificationPermissionsRequestedKey) as bool?) ?? false;

  Future<void> setNotificationPermissionsRequested(bool value) =>
      _box.put(_notificationPermissionsRequestedKey, value);

  AutoBackupFrequency getAutoBackupFrequency() =>
      AutoBackupFrequency.fromStorageKey((_box.get(_autoBackupFrequencyKey) as String?) ?? AutoBackupFrequency.off.storageKey);

  Future<void> setAutoBackupFrequency(AutoBackupFrequency value) => _box.put(_autoBackupFrequencyKey, value.storageKey);

  DateTime? getLastAutoBackupAt() {
    final raw = _box.get(_lastAutoBackupAtKey) as String?;
    return raw == null ? null : DateTime.tryParse(raw);
  }

  Future<void> setLastAutoBackupAt(DateTime value) => _box.put(_lastAutoBackupAtKey, value.toIso8601String());

  /// Whether the app-lock screen should also offer the device's biometric/
  /// credential unlock as a quick alternative to typing the PIN — only
  /// meaningful (and only shown as a toggle in Profile) once a PIN is
  /// actually set. The PIN itself is never optional-out-of once set; this
  /// only controls whether biometric is offered as a shortcut alongside it.
  bool getBiometricUnlockEnabled() => (_box.get(_biometricUnlockEnabledKey) as bool?) ?? false;

  Future<void> setBiometricUnlockEnabled(bool value) => _box.put(_biometricUnlockEnabledKey, value);

  ThemePreference getThemePreference() =>
      ThemePreference.fromStorageKey((_box.get(_themePreferenceKey) as String?) ?? ThemePreference.system.storageKey);

  Future<void> setThemePreference(ThemePreference value) => _box.put(_themePreferenceKey, value.storageKey);

  Future<void> removeLegacyKeys() => _box.deleteAll(_legacyKeys);

  static SettingsRepository openDefault() {
    return SettingsRepository(Hive.box(HiveBoxes.settings));
  }
}
