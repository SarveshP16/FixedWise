import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';

import 'backup_models.dart';

/// The one safeguard against FixedWise's no-cloud-sync local storage:
/// export everything to a single JSON file, or restore from one. Uses
/// `file_picker`'s cross-platform save/pick dialogs rather than writing to
/// a fixed path, so it works the same on Android, iOS, and desktop without
/// extra permission handling.
class LocalBackupService {
  LocalBackupService._();

  /// Opens a save dialog and writes the current export to wherever the
  /// user chooses. Returns `true` if a file was actually saved (`false`
  /// if the user cancelled).
  static Future<bool> exportToFile() async {
    final json = buildExportJson();
    final fileName = 'fixedwise-backup-${DateFormat('yyyy-MM-dd').format(DateTime.now())}.json';
    final uri = await FilePicker.saveFile(
      fileName: fileName,
      bytes: Uint8List.fromList(utf8.encode(json)),
      mimeType: 'application/json',
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    return uri != null;
  }

  /// Opens a pick dialog, parses the chosen file, and returns it
  /// unapplied — call [ParsedBackup.apply] once the caller's confirmed.
  /// Returns `null` if the user cancelled.
  static Future<ParsedBackup?> pickAndParseBackup() async {
    final file = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: ['json']);
    if (file == null) return null;

    final bytes = await file.readAsBytes();
    return parseBackup(utf8.decode(bytes));
  }
}
