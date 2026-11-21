package com.droidlink.networking

import android.util.Log
import com.droidlink.models.BatteryPayload
import com.droidlink.models.DroidMessage
import com.droidlink.models.MessageType
import com.google.gson.Gson
import org.java_websocket.WebSocket
import org.java_websocket.handshake.ClientHandshake
import org.java_websocket.server.WebSocketServer
import java.net.InetSocketAddress

class DroidWebSocketServer(
    port: Int = 8765,
    private val onClientCountChanged: (Int) -> Unit = {}
) : WebSocketServer(InetSocketAddress(port)) {

    private val gson = Gson()
    private val connectedClients = mutableSetOf<WebSocket>()
    private var lastBatteryPayload: BatteryPayload? = null

    init {
        isReuseAddr = true
    }

    override fun onOpen(conn: WebSocket?, handshake: ClientHandshake?) {
        if (conn != null) {
            synchronized(connectedClients) {
                connectedClients.add(conn)
                onClientCountChanged(connectedClients.size)
            }
            Log.d("DroidWebSocketServer", "Yeni istemci bağlandı: ${conn.remoteSocketAddress}")

            // Bağlanan istemciye anında son pil durumunu gönder
            lastBatteryPayload?.let {
                sendBatteryPayload(it, conn)
            }
        }
    }

    override fun onClose(conn: WebSocket?, code: Int, reason: String?, remote: Boolean) {
        if (conn != null) {
            synchronized(connectedClients) {
                connectedClients.remove(conn)
                onClientCountChanged(connectedClients.size)
            }
            Log.d("DroidWebSocketServer", "İstemci ayrıldı: ${conn.remoteSocketAddress}")
        }
    }

    override fun onMessage(conn: WebSocket?, message: String?) {
        Log.d("DroidWebSocketServer", "Mesaj alındı: $message")
        // Gelecek komutlar burada işlenir (dosya transferi isteği, vs.)
    }

    override fun onError(conn: WebSocket?, ex: Exception?) {
        Log.e("DroidWebSocketServer", "WebSocket hatası", ex)
    }

    override fun onStart() {
        Log.i("DroidWebSocketServer", "WebSocket sunucusu port $port üzerinde başlatıldı.")
    }

    fun broadcastBatteryPayload(payload: BatteryPayload) {
        lastBatteryPayload = payload
        synchronized(connectedClients) {
            if (connectedClients.isEmpty()) return
            val msg = DroidMessage(
                type = MessageType.BATTERY_UPDATE,
                payload = payload
            )
            val json = gson.toJson(msg)
            for (client in connectedClients) {
                if (client.isOpen) {
                    client.send(json)
                }
            }
        }
    }

    private fun sendBatteryPayload(payload: BatteryPayload, conn: WebSocket) {
        val msg = DroidMessage(
            type = MessageType.BATTERY_UPDATE,
            payload = payload
        )
        val json = gson.toJson(msg)
        if (conn.isOpen) {
            conn.send(json)
        }
    }
}
