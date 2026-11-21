package com.droidlink.service

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Binder
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import com.droidlink.MainActivity
import com.droidlink.R
import com.droidlink.battery.BatteryMonitor
import com.droidlink.networking.DroidWebSocketServer
import com.droidlink.networking.NsdHelper
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

class DroidLinkForegroundService : Service() {

    private val binder = LocalBinder()
    private val scope = CoroutineScope(Dispatchers.Main + SupervisorJob())

    private lateinit var batteryMonitor: BatteryMonitor
    private var webSocketServer: DroidWebSocketServer? = null
    private lateinit var nsdHelper: NsdHelper

    private val _connectedClientCount = MutableStateFlow(0)
    val connectedClientCount: StateFlow<Int> = _connectedClientCount.asStateFlow()

    inner class LocalBinder : Binder() {
        fun getService(): DroidLinkForegroundService = this@DroidLinkForegroundService
    }

    override fun onBind(intent: Intent?): IBinder = binder

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        startForeground(NOTIFICATION_ID, buildNotification("Servis başlatılıyor..."))

        batteryMonitor = BatteryMonitor(this)
        nsdHelper = NsdHelper(this)

        startServers()
        observeBattery()
    }

    private fun startServers() {
        try {
            webSocketServer = DroidWebSocketServer(8765) { count ->
                _connectedClientCount.value = count
                updateNotification("Bağlı Cihaz: $count")
            }
            webSocketServer?.start()
            nsdHelper.registerService(8765)
            updateNotification("Mac bağlantısı bekleniyor (Port 8765)")
        } catch (e: Exception) {
            Log.e("ForegroundService", "Sunucu başlatma hatası", e)
        }
    }

    private fun observeBattery() {
        batteryMonitor.startMonitoring()
        scope.launch {
            batteryMonitor.batteryState.collect { payload ->
                if (payload != null) {
                    webSocketServer?.broadcastBatteryPayload(payload)
                }
            }
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "DroidLink Eşzamanlama",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Mac ile arka plan eşzamanlamasını sağlar."
            }
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(contentText: String): Notification {
        val intent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("DroidLink Companion")
            .setContentText(contentText)
            .setSmallIcon(android.R.drawable.stat_notify_sync)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .build()
    }

    private fun updateNotification(contentText: String) {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(NOTIFICATION_ID, buildNotification(contentText))
    }

    override fun onDestroy() {
        super.onDestroy()
        scope.cancel()
        batteryMonitor.stopMonitoring()
        nsdHelper.unregisterService()
        try {
            webSocketServer?.stop()
        } catch (e: Exception) {
            Log.e("ForegroundService", "Sunucu durdurulamadı", e)
        }
    }

    companion object {
        private const val CHANNEL_ID = "droidlink_channel"
        private const val NOTIFICATION_ID = 1001
    }
}
