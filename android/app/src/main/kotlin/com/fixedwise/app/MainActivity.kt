package com.fixedwise.app

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.DocumentsContract
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

// local_auth requires a FragmentActivity, not a plain FlutterActivity —
// see lib/core/security/device_auth_service.dart.
//
// Also hosts two small platform channels that have no FOSS-friendly
// plugin equivalent worth a whole dependency:
//  - backup_folder: Storage Access Framework access to one user-chosen
//    folder (lib/core/backup/backup_folder_service.dart), so automatic
//    backups can land somewhere that survives an uninstall — internal
//    storage, an SD card, or any synced folder provider (Nextcloud,
//    Syncthing, …) — with no storage permission and no Google account.
//  - secure_screen: toggles FLAG_SECURE while the app lock is on, so
//    deposit figures never show up in screenshots or the recents preview.
class MainActivity : FlutterFragmentActivity() {
    private val io = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())
    private var pendingPick: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        MethodChannel(messenger, "com.fixedwise.app/backup_folder").setMethodCallHandler(::onBackupFolderCall)
        MethodChannel(messenger, "com.fixedwise.app/secure_screen").setMethodCallHandler { call, result ->
            if (call.method == "setSecure") {
                if (call.arguments as Boolean) {
                    window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                } else {
                    window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                }
                result.success(null)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun onBackupFolderCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "pickFolder" -> pickFolder(result)
            "hasAccess" -> result.success(hasAccess(Uri.parse(call.argument<String>("treeUri"))))
            "release" -> {
                runCatching {
                    contentResolver.releasePersistableUriPermission(
                        Uri.parse(call.argument<String>("treeUri")),
                        Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION,
                    )
                }
                result.success(null)
            }
            "writeFile" -> background(result) {
                writeFile(
                    Uri.parse(call.argument<String>("treeUri")),
                    call.argument<String>("name")!!,
                    call.argument<ByteArray>("bytes")!!,
                )
            }
            "listFiles" -> background(result) { listFiles(Uri.parse(call.argument<String>("treeUri"))) }
            "readFile" -> background(result) {
                contentResolver.openInputStream(Uri.parse(call.argument<String>("uri")))!!.use { it.readBytes() }
            }
            "deleteFile" -> background(result) {
                DocumentsContract.deleteDocument(contentResolver, Uri.parse(call.argument<String>("uri")))
            }
            else -> result.notImplemented()
        }
    }

    // Document providers can be slow (an SD card, a network-backed
    // provider), so file I/O runs off the main thread and only the reply
    // hops back onto it.
    private fun background(result: MethodChannel.Result, work: () -> Any?) {
        io.execute {
            try {
                val value = work()
                main.post { result.success(if (value is Unit) null else value) }
            } catch (error: Exception) {
                main.post { result.error("io", error.message ?: error.toString(), null) }
            }
        }
    }

    private fun pickFolder(result: MethodChannel.Result) {
        if (pendingPick != null) {
            result.error("busy", "A folder picker is already open", null)
            return
        }
        pendingPick = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).addFlags(
            Intent.FLAG_GRANT_READ_URI_PERMISSION or
                Intent.FLAG_GRANT_WRITE_URI_PERMISSION or
                Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION,
        )
        @Suppress("DEPRECATION")
        startActivityForResult(intent, PICK_FOLDER_REQUEST)
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        @Suppress("DEPRECATION")
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != PICK_FOLDER_REQUEST) return
        val result = pendingPick ?: return
        pendingPick = null

        val treeUri = data?.data
        if (resultCode != Activity.RESULT_OK || treeUri == null) {
            result.success(null)
            return
        }
        try {
            contentResolver.takePersistableUriPermission(
                treeUri,
                Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION,
            )
            result.success(mapOf("treeUri" to treeUri.toString(), "name" to folderName(treeUri)))
        } catch (error: Exception) {
            result.error("io", error.message ?: error.toString(), null)
        }
    }

    private fun hasAccess(treeUri: Uri): Boolean =
        contentResolver.persistedUriPermissions.any { it.uri == treeUri && it.isWritePermission }

    private fun folderDocument(treeUri: Uri): Uri =
        DocumentsContract.buildDocumentUriUsingTree(treeUri, DocumentsContract.getTreeDocumentId(treeUri))

    private fun folderName(treeUri: Uri): String {
        contentResolver.query(
            folderDocument(treeUri),
            arrayOf(DocumentsContract.Document.COLUMN_DISPLAY_NAME),
            null,
            null,
            null,
        )?.use { cursor ->
            if (cursor.moveToFirst()) return cursor.getString(0)
        }
        return treeUri.lastPathSegment ?: "Selected folder"
    }

    private fun writeFile(treeUri: Uri, name: String, bytes: ByteArray): String {
        val document = DocumentsContract.createDocument(contentResolver, folderDocument(treeUri), "application/json", name)
            ?: throw IllegalStateException("Couldn't create $name in the backup folder")
        contentResolver.openOutputStream(document, "wt")!!.use { it.write(bytes) }
        return document.toString()
    }

    private fun listFiles(treeUri: Uri): List<Map<String, Any?>> {
        val children = DocumentsContract.buildChildDocumentsUriUsingTree(
            treeUri,
            DocumentsContract.getTreeDocumentId(treeUri),
        )
        val files = mutableListOf<Map<String, Any?>>()
        contentResolver.query(
            children,
            arrayOf(
                DocumentsContract.Document.COLUMN_DOCUMENT_ID,
                DocumentsContract.Document.COLUMN_DISPLAY_NAME,
                DocumentsContract.Document.COLUMN_LAST_MODIFIED,
                DocumentsContract.Document.COLUMN_MIME_TYPE,
            ),
            null,
            null,
            null,
        )?.use { cursor ->
            while (cursor.moveToNext()) {
                if (cursor.getString(3) == DocumentsContract.Document.MIME_TYPE_DIR) continue
                files += mapOf(
                    "uri" to DocumentsContract.buildDocumentUriUsingTree(treeUri, cursor.getString(0)).toString(),
                    "name" to cursor.getString(1),
                    "lastModified" to cursor.getLong(2),
                )
            }
        }
        return files
    }

    companion object {
        private const val PICK_FOLDER_REQUEST = 4201
    }
}
