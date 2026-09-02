import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/notifications/maturity_reminder_service.dart';
import 'core/storage/local_storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStorageService.init();
  await MaturityReminderService.instance.init();
  runApp(const ProviderScope(child: FixedWiseApp()));
}
