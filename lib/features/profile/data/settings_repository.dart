import 'package:hive/hive.dart';

import '../../../core/storage/hive_boxes.dart';

/// Reads/writes simple app-wide preferences — a plain key-value Hive box,
/// not per-record like the holders/deposits boxes, since there's only a
/// handful of scalar settings.
class SettingsRepository {
  SettingsRepository(this._box);

  final Box _box;

  static const _displayNameKey = 'displayName';
  static const _currencySymbolKey = 'currencySymbol';
  static const _notificationLeadDaysKey = 'notificationLeadDays';
  static const _googleDriveConnectedEmailKey = 'googleDriveConnectedEmail';

  static const defaultNotificationLeadDays = 7;

  String? getDisplayName() => _box.get(_displayNameKey) as String?;

  Future<void> setDisplayName(String value) => _box.put(_displayNameKey, value);

  String? getCurrencySymbol() => _box.get(_currencySymbolKey) as String?;

  Future<void> setCurrencySymbol(String value) => _box.put(_currencySymbolKey, value);

  int getNotificationLeadDays() => (_box.get(_notificationLeadDaysKey) as int?) ?? defaultNotificationLeadDays;

  Future<void> setNotificationLeadDays(int value) => _box.put(_notificationLeadDaysKey, value);

  String? getGoogleDriveConnectedEmail() => _box.get(_googleDriveConnectedEmailKey) as String?;

  Future<void> setGoogleDriveConnectedEmail(String? value) async {
    if (value == null) {
      await _box.delete(_googleDriveConnectedEmailKey);
    } else {
      await _box.put(_googleDriveConnectedEmailKey, value);
    }
  }

  static SettingsRepository openDefault() {
    return SettingsRepository(Hive.box(HiveBoxes.settings));
  }
}
