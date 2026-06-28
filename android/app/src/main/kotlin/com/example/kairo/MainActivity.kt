package com.example.kairo

import android.content.ContentValues
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val logTag = "KairoReportDownload"
    private val downloadsChannel = "com.example.kairo/report_downloads"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, downloadsChannel)
            .setMethodCallHandler { call, result ->
                if (call.method != "savePdfToDownloads") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }

                if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
                    Log.d(logTag, "MediaStore save unavailable below Android 10")
                    result.success(false)
                    return@setMethodCallHandler
                }

                val sourcePath = call.argument<String>("sourcePath")
                val fileName = call.argument<String>("fileName")
                if (sourcePath.isNullOrBlank() || fileName.isNullOrBlank()) {
                    Log.e(logTag, "Missing report file details")
                    result.error("invalid_arguments", "Missing report file details", null)
                    return@setMethodCallHandler
                }

                Log.d(logTag, "Platform channel save requested: $sourcePath")
                Thread {
                    savePdfToDownloads(sourcePath, fileName, result)
                }.start()
            }
    }

    private fun savePdfToDownloads(
        sourcePath: String,
        fileName: String,
        result: MethodChannel.Result,
    ) {
        val resolver = applicationContext.contentResolver
        val values = ContentValues().apply {
            put(MediaStore.Downloads.DISPLAY_NAME, fileName)
            put(MediaStore.Downloads.MIME_TYPE, "application/pdf")
            put(MediaStore.Downloads.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
            put(MediaStore.Downloads.IS_PENDING, 1)
        }
        var destination: Uri? = null

        try {
            Log.d(logTag, "Starting MediaStore save: $fileName")
            destination = resolver.insert(
                MediaStore.Downloads.EXTERNAL_CONTENT_URI,
                values,
            )
            Log.d(logTag, "MediaStore destination created: $destination")
            val outputStream = destination?.let(resolver::openOutputStream)
                ?: throw IllegalStateException("Unable to create Downloads file")

            File(sourcePath).inputStream().use { input ->
                outputStream.use { output -> input.copyTo(output) }
            }

            values.clear()
            values.put(MediaStore.Downloads.IS_PENDING, 0)
            resolver.update(destination, values, null, null)
            Log.d(logTag, "MediaStore save succeeded: $destination")
            runOnUiThread {
                Log.d(logTag, "Kotlin platform channel result: true")
                result.success(true)
            }
        } catch (error: Exception) {
            Log.e(logTag, error.toString())
            Log.e(logTag, Log.getStackTraceString(error))
            destination?.let { resolver.delete(it, null, null) }
            runOnUiThread {
                Log.d(logTag, "Kotlin platform channel result: save_failed")
                result.error("save_failed", "Unable to save report", null)
            }
        }
    }
}
