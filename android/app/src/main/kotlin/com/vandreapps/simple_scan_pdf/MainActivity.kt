package com.vandreapps.simple_scan_pdf

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

/// Ponte com o Flutter para documentos (PDF/ODT):
/// - recebe arquivos abertos de fora do app (ação "Abrir com" / ACTION_VIEW);
/// - abre o seletor de arquivos nativo (ACTION_OPEN_DOCUMENT).
class MainActivity : FlutterActivity() {
    private val channelName = "app.simple_scan_pdf/incoming_document"
    private val pickRequestCode = 4321
    private var channel: MethodChannel? = null

    // Guarda o arquivo que abriu o app antes de o Flutter pedir por ele (cold start).
    private var pendingPath: String? = null

    // Resultado pendente do seletor de arquivos nativo.
    private var pickResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
        channel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialDocument" -> {
                    result.success(pendingPath)
                    pendingPath = null
                }
                "pickDocument" -> openPicker(
                    result,
                    arrayOf(
                        "application/pdf",
                        "application/vnd.oasis.opendocument.text",
                        "text/markdown",
                        "text/x-markdown",
                    ),
                )
                "pickImage" -> openPicker(result, arrayOf("image/*"))
                else -> result.notImplemented()
            }
        }
        // Intent que iniciou a Activity (quando o app abre a partir de um arquivo).
        pendingPath = extractDocumentPath(intent)
    }

    /// Abre o seletor nativo (ACTION_OPEN_DOCUMENT) filtrando pelos [mimeTypes]
    /// informados. Não exige permissões de armazenamento.
    private fun openPicker(result: MethodChannel.Result, mimeTypes: Array<String>) {
        if (pickResult != null) {
            result.error("busy", "Já existe uma seleção em andamento.", null)
            return
        }
        pickResult = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "*/*"
            putExtra(Intent.EXTRA_MIME_TYPES, mimeTypes)
        }
        try {
            startActivityForResult(intent, pickRequestCode)
        } catch (e: Exception) {
            pickResult = null
            result.error("no_picker", e.message, null)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != pickRequestCode) return
        val result = pickResult
        pickResult = null
        val uri = data?.data
        if (resultCode == Activity.RESULT_OK && uri != null) {
            result?.success(copyUriToCache(uri))
        } else {
            result?.success(null)
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val path = extractDocumentPath(intent) ?: return
        val activeChannel = channel
        if (activeChannel != null) {
            activeChannel.invokeMethod("onNewDocument", path)
        } else {
            pendingPath = path
        }
    }

    private fun extractDocumentPath(intent: Intent?): String? {
        if (intent == null || intent.action != Intent.ACTION_VIEW) return null
        val uri = intent.data ?: return null
        return copyUriToCache(uri)
    }

    /// Copia o conteúdo do URI recebido para um arquivo no cache do app, já que
    /// content:// não pode ser lido direto como File no Dart. Preserva a
    /// extensão para o Flutter escolher o leitor certo (PDF ou ODT).
    private fun copyUriToCache(uri: Uri): String? {
        return try {
            var safeName = (queryDisplayName(uri) ?: "document")
                .replace(Regex("[/\\\\:*?\"<>|]"), "_")
            if (!safeName.contains('.')) {
                safeName += extensionForMime(contentResolver.getType(uri))
            }
            val outFile = File(cacheDir, "incoming_${System.currentTimeMillis()}_$safeName")
            contentResolver.openInputStream(uri)?.use { input ->
                outFile.outputStream().use { output -> input.copyTo(output) }
            } ?: return null
            outFile.absolutePath
        } catch (e: Exception) {
            null
        }
    }

    private fun extensionForMime(mime: String?): String = when (mime) {
        "application/pdf" -> ".pdf"
        "application/vnd.oasis.opendocument.text" -> ".odt"
        "text/markdown", "text/x-markdown" -> ".md"
        "text/plain" -> ".txt"
        "image/jpeg" -> ".jpg"
        "image/png" -> ".png"
        "image/webp" -> ".webp"
        "image/heic", "image/heif" -> ".heic"
        else -> ""
    }

    private fun queryDisplayName(uri: Uri): String? {
        if (uri.scheme == "file") return uri.lastPathSegment
        var name: String? = null
        contentResolver.query(uri, null, null, null, null)?.use { cursor ->
            if (cursor.moveToFirst()) {
                val index = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                if (index >= 0) name = cursor.getString(index)
            }
        }
        return name
    }
}
