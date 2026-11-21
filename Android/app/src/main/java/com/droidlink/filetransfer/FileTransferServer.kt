package com.droidlink.filetransfer

import android.content.Context
import android.util.Log
import com.droidlink.storage.SafStorageManager
import com.google.gson.Gson
import com.sun.net.httpserver.HttpExchange
import com.sun.net.httpserver.HttpHandler
import com.sun.net.httpserver.HttpServer
import java.io.OutputStream
import java.net.InetSocketAddress
import java.util.concurrent.Executors

class FileTransferServer(
    context: Context,
    private val port: Int = 8766
) {
    private val storageManager = SafStorageManager(context)
    private val gson = Gson()
    private var server: HttpServer? = null
    private val executor = Executors.newFixedThreadPool(4)

    fun start() {
        try {
            val s = HttpServer.create(InetSocketAddress(port), 0)
            s.createContext("/files", ListFilesHandler())
            s.createContext("/upload", UploadHandler())
            s.createContext("/download", DownloadHandler())
            s.executor = executor
            s.start()
            this.server = s
            Log.i("FileTransferServer", "Dosya transfer sunucusu port $port üzerinde çalışıyor.")
        } catch (e: Exception) {
            Log.e("FileTransferServer", "Dosya transfer sunucusu başlatılamadı", e)
        }
    }

    fun stop() {
        server?.stop(0)
        executor.shutdown()
        server = null
    }

    private inner class ListFilesHandler : HttpHandler {
        override fun handle(exchange: HttpExchange?) {
            if (exchange == null) return
            if ("GET".equals(exchange.requestMethod, ignoreCase = true)) {
                val files = storageManager.listReceivedFiles()
                val json = gson.toJson(files)
                val bytes = json.toByteArray(Charsets.UTF_8)

                exchange.responseHeaders.set("Content-Type", "application/json; charset=utf-8")
                exchange.sendResponseHeaders(200, bytes.size.toLong())
                exchange.responseBody.use { it.write(bytes) }
            } else {
                exchange.sendResponseHeaders(405, -1)
            }
        }
    }

    private inner class UploadHandler : HttpHandler {
        override fun handle(exchange: HttpExchange?) {
            if (exchange == null) return
            if ("POST".equals(exchange.requestMethod, ignoreCase = true)) {
                val fileName = exchange.requestHeaders.getFirst("X-File-Name") ?: "received_file"
                val expectedSha256 = exchange.requestHeaders.getFirst("X-File-Sha256")

                val result = storageManager.saveIncomingStream(
                    fileName = fileName,
                    inputStream = exchange.requestBody,
                    expectedSha256 = expectedSha256
                )

                if (result.first) {
                    val resp = "{\"status\":\"OK\",\"sha256\":\"${result.second}\"}"
                    val bytes = resp.toByteArray()
                    exchange.responseHeaders.set("Content-Type", "application/json")
                    exchange.sendResponseHeaders(200, bytes.size.toLong())
                    exchange.responseBody.use { it.write(bytes) }
                } else {
                    val resp = "{\"status\":\"ERROR\",\"message\":\"${result.second}\"}"
                    val bytes = resp.toByteArray()
                    exchange.sendResponseHeaders(400, bytes.size.toLong())
                    exchange.responseBody.use { it.write(bytes) }
                }
            } else {
                exchange.sendResponseHeaders(405, -1)
            }
        }
    }

    private inner class DownloadHandler : HttpHandler {
        override fun handle(exchange: HttpExchange?) {
            if (exchange == null) return
            val query = exchange.requestURI.query ?: ""
            val fileNameParam = query.split("&")
                .firstOrNull { it.startsWith("file=") }
                ?.substringAfter("file=")

            if (fileNameParam.isNullOrBlank()) {
                exchange.sendResponseHeaders(400, -1)
                return
            }

            val stream = storageManager.getFileInputStream(fileNameParam)
            if (stream == null) {
                exchange.sendResponseHeaders(404, -1)
                return
            }

            exchange.responseHeaders.set("Content-Disposition", "attachment; filename=\"$fileNameParam\"")
            exchange.responseHeaders.set("Content-Type", "application/octet-stream")
            exchange.sendResponseHeaders(200, 0) // Chunked streaming

            exchange.responseBody.use { output ->
                stream.use { input ->
                    val buffer = ByteArray(64 * 1024)
                    var read: Int
                    while (input.read(buffer).also { read = it } != -1) {
                        output.write(buffer, 0, read)
                    }
                }
            }
        }
    }
}
