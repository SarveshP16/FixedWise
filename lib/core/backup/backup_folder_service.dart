import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

/// A folder the user picked through Android's own folder picker — kept as
/// a persisted Storage Access Framework grant, so FixedWise can keep
/// writing there across launches with no storage permission at all.
class BackupFolder {
  const BackupFolder({required this.treeUri, required this.name});

  final String treeUri;
  final String name;
}

/// One file inside the [BackupFolder].
class BackupFolderFile {
  const BackupFolderFile({required this.uri, required this.name, required this.lastModified});

  final String uri;
  final String name;
  final DateTime lastModified;
}

/// Thin wrapper over `MainActivity`'s `backup_folder` channel. Android
/// only — every call is a no-op/`null` elsewhere, and Profile hides the
/// automatic-backup section entirely when [isSupported] is false.
///
/// This replaces the earlier Google Drive backup: a chosen folder needs no
/// Google account, no OAuth client and no network access, works on
/// F-Droid builds, and can still end up in the cloud if the user picks a
/// folder that a sync app (Nextcloud, Syncthing, Drive's own app…)
/// already mirrors.
class BackupFolderService {
  BackupFolderService._();

  static final BackupFolderService instance = BackupFolderService._();

  static const _channel = MethodChannel('com.fixedwise.app/backup_folder');

  bool get isSupported => Platform.isAndroid;

  /// Opens the system folder picker. `null` if the user backed out.
  Future<BackupFolder?> pickFolder() async {
    if (!isSupported) return null;
    final result = await _channel.invokeMapMethod<String, String>('pickFolder');
    if (result == null) return null;
    return BackupFolder(treeUri: result['treeUri']!, name: result['name']!);
  }

  /// Whether the persisted grant for [treeUri] is still held — the user
  /// can revoke it from system settings, or the folder's storage (an SD
  /// card) can disappear.
  Future<bool> hasAccess(String treeUri) async {
    if (!isSupported) return false;
    return await _channel.invokeMethod<bool>('hasAccess', {'treeUri': treeUri}) ?? false;
  }

  Future<void> release(String treeUri) async {
    if (!isSupported) return;
    await _channel.invokeMethod<void>('release', {'treeUri': treeUri});
  }

  Future<void> writeText(String treeUri, String name, String contents) {
    return _channel.invokeMethod<String>('writeFile', {
      'treeUri': treeUri,
      'name': name,
      'bytes': Uint8List.fromList(utf8.encode(contents)),
    });
  }

  Future<List<BackupFolderFile>> listFiles(String treeUri) async {
    final raw = await _channel.invokeListMethod<Map<Object?, Object?>>('listFiles', {'treeUri': treeUri}) ?? const [];
    return [
      for (final file in raw)
        BackupFolderFile(
          uri: file['uri']! as String,
          name: file['name']! as String,
          lastModified: DateTime.fromMillisecondsSinceEpoch(file['lastModified']! as int),
        ),
    ];
  }

  Future<String> readText(String uri) async {
    final bytes = await _channel.invokeMethod<Uint8List>('readFile', {'uri': uri});
    return utf8.decode(bytes!);
  }

  Future<void> delete(String uri) => _channel.invokeMethod<void>('deleteFile', {'uri': uri});
}
