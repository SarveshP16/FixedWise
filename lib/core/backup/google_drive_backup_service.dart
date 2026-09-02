import 'dart:convert';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import 'backup_models.dart';

const _driveAppDataScope = 'https://www.googleapis.com/auth/drive.appdata';
const _backupFileName = 'fixedwise_backup.json';

/// The **Web application**-type OAuth client's ID from the FixedWise
/// Google Cloud project — not the Android client's. On Android,
/// `google_sign_in` v7 routes through Android's Credential Manager, which
/// needs this passed as `serverClientId` to identify which OAuth client
/// to request tokens for, even though everything here is a purely
/// client-side (no backend) flow; the Android OAuth client (registered
/// separately with this app's package name + signing SHA-1) is still
/// required for Google to recognize the app at all, but its id never
/// appears in code. OAuth client IDs are public identifiers (unlike
/// client *secrets*), safe to commit — see
/// https://developers.google.com/identity/protocols/oauth2/native-app.
const _androidServerClientId = '325328390604-umapgj6g651h23pgtucrkqo3mhdhisgr.apps.googleusercontent.com';

/// Thrown when Drive backup is attempted before a real Google Sign-In
/// OAuth client has been configured for this app — see this class's own
/// doc comment for what that setup involves.
class GoogleDriveNotConfiguredException implements Exception {
  const GoogleDriveNotConfiguredException([this.detail]);

  final Object? detail;

  @override
  String toString() =>
      "Google Drive backup isn't set up yet"
      '${detail == null ? '.' : ': $detail'}';
}

/// Optional cloud backup layered on top of the local JSON export/import
/// safety net (`local_backup_service.dart`) — stores one JSON snapshot in
/// the signed-in user's Drive **appDataFolder** (an app-private space
/// invisible in the user's own Drive UI and to other apps), via direct
/// Drive v3 REST calls rather than pulling in the full `googleapis` SDK.
///
/// Needed a manual, one-time Google Cloud OAuth setup this dev
/// environment couldn't do itself (the user's own Google account) —
/// **done for Android**: an Android-type client (this app's package name
/// + debug-keystore SHA-1) plus a Web-type client (`_androidServerClientId`
/// above) in the same project, with the Drive API enabled and the
/// `drive.appdata` scope added to the OAuth consent screen. **Not yet
/// done for iOS**: needs its own client id and a reversed-client-id URL
/// scheme in `Info.plist`. Until that's done, iOS calls here throw —
/// `Profile` surfaces that as a friendly message rather than a crash,
/// same pattern Wardro used for its paused AI Stylist feature.
///
/// Also still only registered against a **debug**-signed build — a
/// release build is signed with a different keystore/SHA-1 and will need
/// its own Android OAuth client added to the same project before Drive
/// backup works in a release APK.
class GoogleDriveBackupService {
  GoogleDriveBackupService._();

  static final GoogleDriveBackupService instance = GoogleDriveBackupService._();

  bool _initialized = false;
  GoogleSignInAccount? _account;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    try {
      await GoogleSignIn.instance.initialize(serverClientId: _androidServerClientId);
      _initialized = true;
    } catch (error) {
      throw GoogleDriveNotConfiguredException(error);
    }
  }

  /// Signs the user in and requests Drive appdata access. Returns the
  /// signed-in account's email on success.
  Future<String> connect() async {
    await _ensureInitialized();
    try {
      final account = await GoogleSignIn.instance.authenticate();
      await account.authorizationClient.authorizeScopes([_driveAppDataScope]);
      _account = account;
      return account.email;
    } catch (error) {
      throw GoogleDriveNotConfiguredException(error);
    }
  }

  Future<void> disconnect() async {
    _account = null;
    if (!_initialized) return;
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Best-effort — the app's own "connected" state is what actually
      // gates the feature, not the plugin's internal session.
    }
  }

  /// `_account` only lives in memory — it's set by [connect] but never
  /// survives an app restart on its own. Every fresh launch calls this
  /// first to silently restore a previous sign-in (no UI, no prompt) via
  /// `attemptLightweightAuthentication`, the API's own recommended way to
  /// find out "is someone already signed in" at startup. Without this,
  /// auto-backup (which must run silently, before the user ever revisits
  /// Profile) would fail with "not signed in" on every single launch,
  /// having forgotten a connection that was actually still valid.
  Future<void> _restoreAccountIfNeeded() async {
    if (_account != null) return;
    await _ensureInitialized();
    try {
      final future = GoogleSignIn.instance.attemptLightweightAuthentication();
      final account = await future;
      if (account != null) _account = account;
    } catch (_) {
      // No restorable session — callers that need one will report that
      // via the "not signed in" branch below.
    }
  }

  Future<Map<String, String>> _authHeaders({required bool interactive}) async {
    await _restoreAccountIfNeeded();
    final account = _account;
    if (account == null) throw const GoogleDriveNotConfiguredException('not signed in');
    final headers = await account.authorizationClient.authorizationHeaders(
      [_driveAppDataScope],
      promptIfNecessary: interactive,
    );
    if (headers == null) throw const GoogleDriveNotConfiguredException('authorization was not granted');
    return headers;
  }

  Future<String?> _findBackupFileId(Map<String, String> headers) async {
    final uri = Uri.https('www.googleapis.com', '/drive/v3/files', {
      'spaces': 'appDataFolder',
      'q': "name = '$_backupFileName' and trashed = false",
      'fields': 'files(id)',
    });
    final response = await http.get(uri, headers: headers);
    if (response.statusCode != 200) {
      throw GoogleDriveNotConfiguredException('Drive lookup failed (${response.statusCode})');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final files = (body['files'] as List<dynamic>?) ?? const [];
    if (files.isEmpty) return null;
    return (files.first as Map<String, dynamic>)['id'] as String?;
  }

  /// Uploads the current export as this Drive account's single backup
  /// snapshot, replacing any previous one. [interactive] controls whether
  /// a stale/expired authorization is allowed to prompt the user —
  /// `false` for the silent auto-backup path (a surprise sign-in prompt
  /// mid-launch would defeat the point of "silent"), `true` for a manual
  /// "Back up now" tap.
  Future<void> backup({bool interactive = true}) async {
    final headers = await _authHeaders(interactive: interactive);
    final json = buildExportJson();
    final existingId = await _findBackupFileId(headers);

    if (existingId != null) {
      final uri = Uri.https('www.googleapis.com', '/upload/drive/v3/files/$existingId', {'uploadType': 'media'});
      final response = await http.patch(
        uri,
        headers: {...headers, 'Content-Type': 'application/json'},
        body: json,
      );
      if (response.statusCode != 200) {
        throw GoogleDriveNotConfiguredException('Drive upload failed (${response.statusCode})');
      }
      return;
    }

    const boundary = 'fixedwise-backup-boundary';
    final metadata = jsonEncode({
      'name': _backupFileName,
      'parents': ['appDataFolder'],
    });
    final body =
        '--$boundary\r\n'
        'Content-Type: application/json; charset=UTF-8\r\n\r\n'
        '$metadata\r\n'
        '--$boundary\r\n'
        'Content-Type: application/json\r\n\r\n'
        '$json\r\n'
        '--$boundary--';
    final uri = Uri.https('www.googleapis.com', '/upload/drive/v3/files', {'uploadType': 'multipart'});
    final response = await http.post(
      uri,
      headers: {...headers, 'Content-Type': 'multipart/related; boundary=$boundary'},
      body: body,
    );
    if (response.statusCode != 200) {
      throw GoogleDriveNotConfiguredException('Drive upload failed (${response.statusCode})');
    }
  }

  /// Downloads and parses the Drive backup snapshot, or `null` if this
  /// account has never backed up before.
  Future<ParsedBackup?> restore() async {
    final headers = await _authHeaders(interactive: true);
    final fileId = await _findBackupFileId(headers);
    if (fileId == null) return null;

    final uri = Uri.https('www.googleapis.com', '/drive/v3/files/$fileId', {'alt': 'media'});
    final response = await http.get(uri, headers: headers);
    if (response.statusCode != 200) {
      throw GoogleDriveNotConfiguredException('Drive download failed (${response.statusCode})');
    }
    return parseBackup(response.body);
  }
}
