import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/backup/auto_backup_frequency.dart';
import '../../../core/theme/theme_preference.dart';
import '../../../core/utils/currency_formatter.dart' show settingsRepositoryProvider;
import '../data/settings_repository.dart';

/// The user's own display name, shown in the dashboard's greeting
/// ("Good morning, {name}"). Defaults to "there" until set.
final displayNameProvider = StateNotifierProvider<DisplayNameNotifier, String>((ref) {
  return DisplayNameNotifier(ref.watch(settingsRepositoryProvider));
});

class DisplayNameNotifier extends StateNotifier<String> {
  DisplayNameNotifier(this._repository) : super(_repository.getDisplayName() ?? 'there');

  final SettingsRepository _repository;

  Future<void> setName(String name) async {
    state = name;
    await _repository.setDisplayName(name);
  }
}

/// How many days before an FD's maturity date its reminder notification
/// fires. Changing this reschedules every FD's reminder (see
/// `MaturityReminderSync.rescheduleAll`).
final notificationLeadDaysProvider = StateNotifierProvider<NotificationLeadDaysNotifier, int>((ref) {
  return NotificationLeadDaysNotifier(ref.watch(settingsRepositoryProvider));
});

class NotificationLeadDaysNotifier extends StateNotifier<int> {
  NotificationLeadDaysNotifier(this._repository) : super(_repository.getNotificationLeadDays());

  final SettingsRepository _repository;

  Future<void> setLeadDays(int days) async {
    state = days;
    await _repository.setNotificationLeadDays(days);
  }
}

/// The connected Google account's email if Drive backup is set up, else
/// `null` — Profile shows "Not connected" until this is set.
final googleDriveConnectedEmailProvider = StateNotifierProvider<GoogleDriveConnectedEmailNotifier, String?>((ref) {
  return GoogleDriveConnectedEmailNotifier(ref.watch(settingsRepositoryProvider));
});

class GoogleDriveConnectedEmailNotifier extends StateNotifier<String?> {
  GoogleDriveConnectedEmailNotifier(this._repository) : super(_repository.getGoogleDriveConnectedEmail());

  final SettingsRepository _repository;

  Future<void> setEmail(String? email) async {
    state = email;
    await _repository.setGoogleDriveConnectedEmail(email);
  }
}

/// How often FixedWise checks-and-runs a Drive backup on app launch —
/// see `auto_backup.dart`. Changing this doesn't itself trigger a
/// backup; the next launch's check picks up the new setting.
final autoBackupFrequencyProvider = StateNotifierProvider<AutoBackupFrequencyNotifier, AutoBackupFrequency>((ref) {
  return AutoBackupFrequencyNotifier(ref.watch(settingsRepositoryProvider));
});

class AutoBackupFrequencyNotifier extends StateNotifier<AutoBackupFrequency> {
  AutoBackupFrequencyNotifier(this._repository) : super(_repository.getAutoBackupFrequency());

  final SettingsRepository _repository;

  Future<void> setFrequency(AutoBackupFrequency frequency) async {
    state = frequency;
    await _repository.setAutoBackupFrequency(frequency);
  }
}

/// When the last successful Drive backup (auto or manual) completed, for
/// Profile's "Last backup" line — `null` if there's never been one.
final lastGoogleDriveBackupAtProvider = StateNotifierProvider<LastGoogleDriveBackupAtNotifier, DateTime?>((ref) {
  return LastGoogleDriveBackupAtNotifier(ref.watch(settingsRepositoryProvider));
});

class LastGoogleDriveBackupAtNotifier extends StateNotifier<DateTime?> {
  LastGoogleDriveBackupAtNotifier(this._repository) : super(_repository.getLastGoogleDriveBackupAt());

  final SettingsRepository _repository;

  Future<void> recordNow() async {
    final now = DateTime.now();
    state = now;
    await _repository.setLastGoogleDriveBackupAt(now);
  }
}

/// The user's chosen appearance (system/light/dark) — see [ThemePreference].
final themePreferenceProvider = StateNotifierProvider<ThemePreferenceNotifier, ThemePreference>((ref) {
  return ThemePreferenceNotifier(ref.watch(settingsRepositoryProvider));
});

class ThemePreferenceNotifier extends StateNotifier<ThemePreference> {
  ThemePreferenceNotifier(this._repository) : super(_repository.getThemePreference());

  final SettingsRepository _repository;

  Future<void> setPreference(ThemePreference preference) async {
    state = preference;
    await _repository.setThemePreference(preference);
  }
}

/// App name + version, read once from the platform, for Profile's About row.
final packageInfoProvider = FutureProvider<PackageInfo>((ref) {
  return PackageInfo.fromPlatform();
});
