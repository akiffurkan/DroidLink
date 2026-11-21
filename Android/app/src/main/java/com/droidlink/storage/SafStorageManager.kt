package com.droidlink.storage

import android.content.ContentValues
import android.content.Context
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import java.io.File
import java.io.InputStream
import java.io.OutputStream
import java.security.MessageDigest

class SafStorageManager(private val context: Context) {

    data class FileMeta(
        val name: String,
        val size: Long,
        val mimeType: String,
        val lastModified: Long
    )

    fun listReceivedFiles(): List<FileMeta> {
        val files = mutableListOf<FileMeta>()
        val dir = getAppDownloadDir()
        if (dir.exists() && dir.isDirectory) {
            dir.listFiles()?.forEach { file ->
                if (file.isFile) {
                    files.add(
                        FileMeta(
                            name = file.name,
                            size = file.length(),
                            mimeType = getMimeType(file.name),
                            lastModified = file.lastModified()
                        )
                    )
                }
            }
        }
        return files
    }

    fun saveIncomingStream(
        fileName: String,
        inputStream: InputStream,
        expectedSha256: String? = null
    ): Pair<Boolean, String?> {
        val sanitizedName = sanitizeFileName(fileName)
        val targetDir = getAppDownloadDir()
        if (!targetDir.exists()) {
            targetDir.mkdirs()
        }

        val targetFile = File(targetDir, sanitizedName)
        val digest = MessageDigest.getInstance("SHA-256")

        try {
            targetFile.outputStream().use { output ->
                val buffer = ByteArray(64 * 1024)
                var bytesRead: Int
                while (inputStream.read(buffer).also { bytesRead = it } != -1) {
                    output.write(buffer, 0, bytesRead)
                    digest.update(buffer, 0, bytesRead)
                }
            }

            val computedSha256 = digest.digest().joinToString("") { "%02x".format(it) }
            if (expectedSha256 != null && !computedSha256.equals(expectedSha256, ignoreCase = true)) {
                targetFile.delete()
                return Pair(false, "Checksum mismatch")
            }

            return Pair(true, computedSha256)
        } catch (e: Exception) {
            targetFile.delete()
            return Pair(false, e.localizedMessage)
        }
    }

    fun getFileInputStream(fileName: String): InputStream? {
        val sanitized = sanitizeFileName(fileName)
        val file = File(getAppDownloadDir(), sanitized)
        return if (file.exists() && file.isFile) file.inputStream() else null
    }

    private fun getAppDownloadDir(): File {
        val baseDownload = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
        return File(baseDownload, "DroidLink")
    }

    private fun sanitizeFileName(name: String): String {
        return name.replace("[/\\\\?%*|\"<>:]".toRegex(), "_")
            .replace("..", "")
    }

    private fun getMimeType(name: String): String {
        val ext = name.substringAfterLast('.', "")
        return when (ext.lowercase()) {
            "jpg", "jpeg" -> "image/jpeg"
            "png" -> "image/png"
            "pdf" -> "application/pdf"
            "zip" -> "application/zip"
            "mp4" -> "video/mp4"
            "mp3" -> "audio/mpeg"
            else -> "application/octet-stream"
        }
    }
}
