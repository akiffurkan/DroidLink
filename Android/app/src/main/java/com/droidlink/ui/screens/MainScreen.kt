package com.droidlink.ui.screens

import android.content.Context
import android.net.wifi.WifiManager
import android.text.format.Formatter
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.droidlink.battery.BatteryMonitor
import com.droidlink.models.BatteryPayload
import com.droidlink.models.ChargingSource
import com.droidlink.ui.theme.GreenAccent
import com.droidlink.ui.theme.RedAccent
import com.droidlink.ui.theme.YellowAccent

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MainScreen(
    batteryPayload: BatteryPayload?,
    connectedClients: Int,
    isServiceRunning: Boolean,
    onToggleService: () -> Unit
) {
    val context = LocalContext.current
    val ipAddress = remember { getLocalIpAddress(context) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("DroidLink", fontWeight = FontWeight.Bold) },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.background
                )
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Bağlantı ve IP Kartı
            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(16.dp),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Text(
                        text = "Yerel Bağlantı Bilgisi",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.SemiBold
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(
                        text = "IP: $ipAddress : 8765",
                        style = MaterialTheme.typography.bodyLarge,
                        color = MaterialTheme.colorScheme.primary
                    )
                    Spacer(modifier = Modifier.height(4.dp))
                    Text(
                        text = if (connectedClients > 0) "🟢 $connectedClients Mac Bağlı" else "⚪ Mac Bağlantısı Bekleniyor",
                        style = MaterialTheme.typography.bodyMedium,
                        color = if (connectedClients > 0) GreenAccent else Color.Gray
                    )
                }
            }

            // Gerçek Pil Durum Kartı
            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(16.dp),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
            ) {
                Column(
                    modifier = Modifier.padding(20.dp),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Text(
                        text = "Telefon Pil Seviyesi",
                        style = MaterialTheme.typography.labelLarge,
                        color = Color.Gray
                    )

                    val level = batteryPayload?.batteryLevel ?: 0
                    val isCharging = batteryPayload?.isCharging ?: false

                    Text(
                        text = "$level%",
                        fontSize = 54.sp,
                        fontWeight = FontWeight.Bold,
                        color = when {
                            level <= 20 -> RedAccent
                            level <= 40 -> YellowAccent
                            else -> GreenAccent
                        }
                    )

                    Spacer(modifier = Modifier.height(6.dp))

                    Text(
                        text = if (isCharging) "⚡ Şarj Ediliyor (${batteryPayload?.chargingSource?.name ?: "Bilinmiyor"})" else "Pilden Kullanılıyor",
                        style = MaterialTheme.typography.bodyMedium,
                        fontWeight = FontWeight.Medium
                    )

                    if (batteryPayload?.temperature != null) {
                        Spacer(modifier = Modifier.height(8.dp))
                        Text(
                            text = "Sıcaklık: ${String.format("%.1f", batteryPayload.temperature)} °C",
                            style = MaterialTheme.typography.bodySmall,
                            color = Color.Gray
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.weight(1f))

            // Servis Başlat / Durdur Butonu
            Button(
                onClick = onToggleService,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(52.dp),
                shape = RoundedCornerShape(12.dp),
                colors = ButtonDefaults.buttonColors(
                    containerColor = if (isServiceRunning) MaterialTheme.colorScheme.error else MaterialTheme.colorScheme.primary
                )
            ) {
                Text(
                    text = if (isServiceRunning) "Servisi Durdur" else "Servisi Başlat",
                    fontWeight = FontWeight.SemiBold,
                    fontSize = 16.sp
                )
            }
        }
    }
}

private fun getLocalIpAddress(context: Context): String {
    val wifiManager = context.applicationContext.getSystemService(Context.WIFI_SERVICE) as? WifiManager
    val ipInt = wifiManager?.connectionInfo?.ipAddress ?: 0
    return if (ipInt != 0) {
        Formatter.formatIpAddress(ipInt)
    } else {
        "127.0.0.1"
    }
}
