import 'package:flutter/material.dart';

/// The user's chosen appearance — [system] (the default) follows the OS,
/// [light]/[dark] pin FixedWise to one regardless of the OS setting.
enum ThemePreference {
  system(storageKey: 'system', label: 'System'),
  light(storageKey: 'light', label: 'Light'),
  dark(storageKey: 'dark', label: 'Dark');

  const ThemePreference({required this.storageKey, required this.label});

  final String storageKey;
  final String label;

  ThemeMode get themeMode => switch (this) {
    ThemePreference.system => ThemeMode.system,
    ThemePreference.light => ThemeMode.light,
    ThemePreference.dark => ThemeMode.dark,
  };

  static ThemePreference fromStorageKey(String key) {
    return ThemePreference.values.firstWhere((value) => value.storageKey == key, orElse: () => ThemePreference.system);
  }
}
