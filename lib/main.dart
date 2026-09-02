import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/notifications/maturity_reminder_service.dart';
import 'core/storage/local_storage_service.dart';
import 'features/profile/data/settings_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStorageService.init();

  // Ask for notification/exact-alarm permissions at most once ever — see
  // MaturityReminderService.init's doc comment for why.
  final settings = SettingsRepository.openDefault();
  final alreadyAskedForPermissions = settings.getNotificationPermissionsRequested();
  await MaturityReminderService.instance.init(requestPermissions: !alreadyAskedForPermissions);
  if (!alreadyAskedForPermissions) {
    await settings.setNotificationPermissionsRequested(true);
  }

  runApp(const ProviderScope(child: FixedWiseApp()));
}
