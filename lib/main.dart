import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/backup/auto_backup.dart';
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

  // Fire-and-forget: a silent Drive upload has no business delaying the
  // very first frame. See auto_backup.dart for what "due" means and why
  // this checks once at launch rather than on a true background schedule.
  unawaited(runAutoBackupIfDue());

  runApp(const ProviderScope(child: FixedWiseApp()));
}
