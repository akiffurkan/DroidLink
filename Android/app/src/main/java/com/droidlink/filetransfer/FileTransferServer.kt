package com.droidlink.filetransfer

import android.content.Context
import android.util.Log
import com.droidlink.storage.SafStorageManager
import com.google.gson.Gson
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import java.io.ByteArrayOutputStream
import java.io.InputStream
import java.io.OutputStream
import java.net.ServerSocket
import java.net.Socket
import java.net.URLDecoder

class FileTransferServer(
    context: Context,
    private val port: Int = 8766
) {
    private val storageManager = SafStorageManager(context)
    private val gson = Gson()
    private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    private var serverSocket: ServerSocket? = null

    fun start() {
        scope.launch {
            try {
                serverSocket = ServerSocket(port).apply {
                    reuseAddress = true
                }
                Log.i("FileTransferServer", "Dosya sunucusu port $port üzerinde dinliyor.")

                while (isActive) {
                    val socket = serverSocket?.accept() ?: break
                    launch {
                        handleClient(socket)
                    }
                }
            } catch (e: Exception) {
                if (isActive) {
                    Log.e("FileTransferServer", "Sunucu hatası: ${e.message}")
                }
            }
        }
    }

    fun stop() {
        scope.cancel()
        try {
            serverSocket?.close()
        } catch (_: Exception) {}
        serverSocket = null
    }

    private fun readHeaderLine(input: InputStream): String? {
        val baos = ByteArrayOutputStream()
        var prev = -1
        while (true) {
            val c = input.read()
            if (c == -1) {
                return if (baos.size() > 0) baos.toString("UTF-8") else null
            }
            if (c == '\n'.code) {
                val bytes = baos.toByteArray()
                val len = if (bytes.isNotEmpty() && bytes.last() == '\r'.code.toByte()) bytes.size - 1 else bytes.size
                return String(bytes, 0, len, Charsets.UTF_8)
            }
            baos.write(c)
        }
    }

    private fun handleClient(socket: Socket) {
        socket.use { s ->
            try {
                val input = s.getInputStream()
                val output = s.getOutputStream()

                val requestLine = readHeaderLine(input) ?: return
                val parts = requestLine.split(" ")
                if (parts.size < 2) return

                val method = parts[0]
                val path = parts[1]

                // Başlıkları oku
                val headers = mutableMapOf<String, String>()
                while (true) {
                    val line = readHeaderLine(input) ?: break
                    if (line.isEmpty()) break
                    val colonIdx = line.indexOf(':')
                    if (colonIdx > 0) {
                        val key = line.substring(0, colonIdx).trim().lowercase()
                        val value = line.substring(colonIdx + 1).trim()
                        headers[key] = value
                    }
                }

                when {
                    method.equals("GET", ignoreCase = true) && path == "/files" -> {
                        val files = storageManager.listReceivedFiles()
                        val json = gson.toJson(files)
                        val bytes = json.toByteArray(Charsets.UTF_8)
                        val response = "HTTP/1.1 200 OK\r\n" +
                                "Content-Type: application/json; charset=utf-8\r\n" +
                                "Content-Length: ${bytes.size}\r\n" +
                                "Connection: close\r\n\r\n"
                        output.write(response.toByteArray(Charsets.UTF_8))
                        output.write(bytes)
                        output.flush()
                    }

                    method.equals("POST", ignoreCase = true) && path == "/upload" -> {
                        val fileName = headers["x-file-name"] ?: "received_file"
                        val expectedSha256 = headers["x-file-sha256"]
                        val contentLength = headers["content-length"]?.toLongOrNull()

                        val bodyStream = if (contentLength != null && contentLength >= 0) {
                            BoundedInputStream(input, contentLength)
                        } else {
                            input
                        }

                        val result = storageManager.saveIncomingStream(
                            fileName = fileName,
                            inputStream = bodyStream,
                            expectedSha256 = expectedSha256
                        )

                        if (result.first) {
                            val resp = "{\"status\":\"OK\",\"sha256\":\"${result.second}\"}"
                            val bytes = resp.toByteArray(Charsets.UTF_8)
                            val response = "HTTP/1.1 200 OK\r\n" +
                                    "Content-Type: application/json\r\n" +
                                    "Content-Length: ${bytes.size}\r\n" +
                                    "Connection: close\r\n\r\n"
                            output.write(response.toByteArray(Charsets.UTF_8))
                            output.write(bytes)
                        } else {
                            val resp = "{\"status\":\"ERROR\",\"message\":\"${result.second}\"}"
                            val bytes = resp.toByteArray(Charsets.UTF_8)
                            val response = "HTTP/1.1 400 Bad Request\r\n" +
                                    "Content-Type: application/json\r\n" +
                                    "Content-Length: ${bytes.size}\r\n" +
                                    "Connection: close\r\n\r\n"
                            output.write(response.toByteArray(Charsets.UTF_8))
                            output.write(bytes)
                        }
                        output.flush()
                    }

                    method.equals("GET", ignoreCase = true) && path.startsWith("/download") -> {
                        val query = if (path.contains("?")) path.substringAfter("?") else ""
                        val fileParam = query.split("&")
                            .firstOrNull { it.startsWith("file=") }
                            ?.substringAfter("file=")

                        val fileName = if (!fileParam.isNullOrBlank()) URLDecoder.decode(fileParam, "UTF-8") else null
                        val fileStream = fileName?.let { storageManager.getFileInputStream(it) }

                        if (fileStream != null) {
                            val response = "HTTP/1.1 200 OK\r\n" +
                                    "Content-Disposition: attachment; filename=\"$fileName\"\r\n" +
                                    "Content-Type: application/octet-stream\r\n" +
                                    "Transfer-Encoding: chunked\r\n" +
                                    "Connection: close\r\n\r\n"
                            output.write(response.toByteArray(Charsets.UTF_8))

                            fileStream.use { fs ->
                                val buffer = ByteArray(64 * 1024)
                                var read: Int
                                while (fs.read(buffer).also { read = it } != -1) {
                                    val chunkSizeHex = Integer.toHexString(read)
                                    output.write("$chunkSizeHex\r\n".toByteArray(Charsets.UTF_8))
                                    output.write(buffer, 0, read)
                                    output.write("\r\n".toByteArray(Charsets.UTF_8))
                                }
                                output.write("0\r\n\r\n".toByteArray(Charsets.UTF_8))
                            }
                            output.flush()
                        } else {
                            val notFound = "HTTP/1.1 404 Not Found\r\nContent-Length: 0\r\nConnection: close\r\n\r\n"
                            output.write(notFound.toByteArray(Charsets.UTF_8))
                            output.flush()
                        }
                    }

                    else -> {
                        val notAllowed = "HTTP/1.1 405 Method Not Allowed\r\nContent-Length: 0\r\nConnection: close\r\n\r\n"
                        output.write(notAllowed.toByteArray(Charsets.UTF_8))
                        output.flush()
                    }
                }
            } catch (e: Exception) {
                Log.e("FileTransferServer", "İstemci işleme hatası: ${e.message}")
            }
        }
    }

    private class BoundedInputStream(
        private val stream: InputStream,
        private val limit: Long
    ) : InputStream() {
        private var bytesRead: Long = 0

        override fun read(): Int {
            if (bytesRead >= limit) return -1
            val b = stream.read()
            if (b != -1) bytesRead++
            return b
        }

        override fun read(b: ByteArray, off: Int, len: Int): Int {
            if (bytesRead >= limit) return -1
            val maxToRead = minOf(len.toLong(), limit - bytesRead).toInt()
            val read = stream.read(b, off, maxToRead)
            if (read != -1) bytesRead += read
            return read
        }
    }
}
