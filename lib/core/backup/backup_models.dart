import 'dart:convert';

import 'package:hive/hive.dart';

import '../storage/hive_boxes.dart';

const _backupFormatVersion = 1;

/// Builds a single JSON document containing every Hive box FixedWise
/// keeps: holders, deposits, and settings — the one file a user can move
/// between devices or keep as a safety net, since storage is otherwise
/// 100% local with no cloud sync.
String buildExportJson() {
  final holders = Hive.box<Map>(HiveBoxes.holders).values.toList();
  final deposits = Hive.box<Map>(HiveBoxes.fixedDeposits).values.toList();
  final settings = Hive.box(HiveBoxes.settings).toMap();

  final document = {
    'fixedwiseExport': true,
    'formatVersion': _backupFormatVersion,
    'exportedAt': DateTime.now().toIso8601String(),
    'data': {
      'holders': holders,
      'fixedDeposits': deposits,
      'settings': settings.map((key, value) => MapEntry(key.toString(), value)),
    },
  };
  return const JsonEncoder.withIndent('  ').convert(document);
}

/// Thrown by [parseBackup] when given something that isn't a recognizable
/// FixedWise export.
class InvalidBackupException implements Exception {
  const InvalidBackupException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// The parsed, not-yet-applied contents of a backup file. [exportedAt]
/// lets the caller show a confirmation with real information ("restore
/// from Aug 29?") rather than a blind "are you sure?".
class ParsedBackup {
  const ParsedBackup({
    required this.exportedAt,
    required this.holders,
    required this.fixedDeposits,
    required this.settings,
  });

  final DateTime? exportedAt;
  final List<Map<String, dynamic>> holders;
  final List<Map<String, dynamic>> fixedDeposits;
  final Map<String, dynamic> settings;

  /// Replaces every holder/deposit with the backup's versions and merges
  /// the settings values in — overwrites whatever's there now. Called only
  /// after the caller has shown a confirmation naming [exportedAt].
  Future<void> apply() async {
    final holdersBox = Hive.box<Map>(HiveBoxes.holders);
    final depositsBox = Hive.box<Map>(HiveBoxes.fixedDeposits);
    final settingsBox = Hive.box(HiveBoxes.settings);

    await holdersBox.clear();
    for (final holder in holders) {
      final id = holder['id'] as String?;
      if (id != null) await holdersBox.put(id, holder);
    }

    await depositsBox.clear();
    for (final deposit in fixedDeposits) {
      final id = deposit['id'] as String?;
      if (id != null) await depositsBox.put(id, deposit);
    }

    for (final entry in settings.entries) {
      await settingsBox.put(entry.key, entry.value);
    }
  }
}

/// Parses and validates [json] as a FixedWise export without writing
/// anything — call [ParsedBackup.apply] once the caller's confirmed.
/// Throws [InvalidBackupException] if [json] isn't recognizable.
ParsedBackup parseBackup(String json) {
  final Object? decoded;
  try {
    decoded = jsonDecode(json);
  } on FormatException {
    throw const InvalidBackupException("That file isn't valid JSON.");
  }

  if (decoded is! Map<String, dynamic> || decoded['fixedwiseExport'] != true) {
    throw const InvalidBackupException("That file isn't a FixedWise backup.");
  }

  final rawData = decoded['data'];
  if (rawData is! Map<String, dynamic>) {
    throw const InvalidBackupException("That file isn't a FixedWise backup.");
  }

  final rawHolders = rawData['holders'];
  final rawDeposits = rawData['fixedDeposits'];
  final rawSettings = rawData['settings'];

  final exportedAtRaw = decoded['exportedAt'];
  final exportedAt = exportedAtRaw is String ? DateTime.tryParse(exportedAtRaw) : null;

  return ParsedBackup(
    exportedAt: exportedAt,
    holders: rawHolders is List ? rawHolders.cast<Map<String, dynamic>>() : const [],
    fixedDeposits: rawDeposits is List ? rawDeposits.cast<Map<String, dynamic>>() : const [],
    settings: rawSettings is Map<String, dynamic> ? rawSettings : const {},
  );
}
