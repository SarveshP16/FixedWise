import 'package:hive_flutter/hive_flutter.dart';

import 'hive_boxes.dart';

/// Boots Hive and opens every box the app needs, once, before [runApp].
/// FixedWise is local-first (with an optional Google Drive backup layered
/// on top later) — there is no backend to fall back to, so this must
/// succeed before anything else runs.
class LocalStorageService {
  LocalStorageService._();

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<Map>(HiveBoxes.holders);
    await Hive.openBox<Map>(HiveBoxes.fixedDeposits);
    await Hive.openBox(HiveBoxes.settings);
  }
}
