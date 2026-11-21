package com.droidlink

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.os.Build
import android.os.Bundle
import android.os.IBinder
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.runtime.*
import com.droidlink.battery.BatteryMonitor
import com.droidlink.models.BatteryPayload
import com.droidlink.service.DroidLinkForegroundService
import com.droidlink.ui.screens.MainScreen
import com.droidlink.ui.theme.DroidLinkTheme

class MainActivity : ComponentActivity() {

    private var foregroundService: DroidLinkForegroundService? = null
    private var isBound = false
    private lateinit var batteryMonitor: BatteryMonitor

    private val serviceConnection = object : ServiceConnection {
        override fun onServiceConnected(name: ComponentName?, service: IBinder?) {
            val binder = service as DroidLinkForegroundService.LocalBinder
            foregroundService = binder.getService()
            isBound = true
        }

        override fun onServiceDisconnected(name: ComponentName?) {
            foregroundService = null
            isBound = false
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        batteryMonitor = BatteryMonitor(this)
        batteryMonitor.startMonitoring()

        startForegroundService()

        setContent {
            DroidLinkTheme {
                val batteryPayload by batteryMonitor.batteryState.collectAsState()
                var isRunning by remember { mutableStateOf(true) }

                MainScreen(
                    batteryPayload = batteryPayload,
                    connectedClients = 0,
                    isServiceRunning = isRunning,
                    onToggleService = {
                        if (isRunning) {
                            stopForegroundService()
                            isRunning = false
                        } else {
                            startForegroundService()
                            isRunning = true
                        }
                    }
                )
            }
        }
    }

    private fun startForegroundService() {
        val intent = Intent(this, DroidLinkForegroundService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
        bindService(intent, serviceConnection, Context.BIND_AUTO_CREATE)
    }

    private fun stopForegroundService() {
        if (isBound) {
            unbindService(serviceConnection)
            isBound = false
        }
        val intent = Intent(this, DroidLinkForegroundService::class.java)
        stopService(intent)
    }

    override fun onDestroy() {
        super.onDestroy()
        batteryMonitor.stopMonitoring()
        if (isBound) {
            unbindService(serviceConnection)
            isBound = false
        }
    }
}
