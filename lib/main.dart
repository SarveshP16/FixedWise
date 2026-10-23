import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/backup/auto_backup.dart';
import 'core/notifications/maturity_reminder_service.dart';
import 'core/storage/local_storage_service.dart';
import 'features/profile/data/settings_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _registerFontLicenses();
  await LocalStorageService.init();

  // Ask for notification/exact-alarm permissions at most once ever — see
  // MaturityReminderService.init's doc comment for why.
  final settings = SettingsRepository.openDefault();
  await settings.removeLegacyKeys();
  final alreadyAskedForPermissions = settings.getNotificationPermissionsRequested();
  await MaturityReminderService.instance.init(requestPermissions: !alreadyAskedForPermissions);
  if (!alreadyAskedForPermissions) {
    await settings.setNotificationPermissionsRequested(true);
  }

  // Fire-and-forget: a silent backup write has no business delaying the
  // very first frame. See auto_backup.dart for what "due" means and why
  // this checks once at launch rather than on a true background schedule.
  unawaited(runAutoBackupIfDue());

  runApp(const ProviderScope(child: FixedWiseApp()));
}

/// The bundled fonts' SIL Open Font Licenses, so they show up alongside
/// every package license on the About screen's licenses page — the OFL
/// requires the license to travel with the font.
void _registerFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    for (final (family, file) in [('Fraunces', 'Fraunces-OFL.txt'), ('IBM Plex Sans', 'IBMPlexSans-OFL.txt')]) {
      yield LicenseEntryWithLineBreaks([family], await rootBundle.loadString('assets/fonts/$file'));
    }
  });
}
