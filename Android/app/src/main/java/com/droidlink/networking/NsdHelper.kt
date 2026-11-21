package com.droidlink.networking

import android.content.Context
import android.net.nsd.NsdManager
import android.net.nsd.NsdServiceInfo
import android.os.Build
import android.util.Log

class NsdHelper(private val context: Context) {

    private val nsdManager: NsdManager? by lazy {
        context.getSystemService(Context.NSD_SERVICE) as? NsdManager
    }

    private var registrationListener: NsdManager.RegistrationListener? = null
    private var isRegistered = false

    fun registerService(port: Int = 8765) {
        if (isRegistered) return

        val serviceInfo = NsdServiceInfo().apply {
            serviceName = "DroidLink-${Build.MODEL.replace(" ", "-")}"
            serviceType = "_droidlink._tcp."
            setPort(port)
        }

        registrationListener = object : NsdManager.RegistrationListener {
            override fun onServiceRegistered(serviceInfo: NsdServiceInfo) {
                isRegistered = true
                Log.d("NsdHelper", "mDNS servisi kaydedildi: ${serviceInfo.serviceName}")
            }

            override fun onRegistrationFailed(serviceInfo: NsdServiceInfo, errorCode: Int) {
                Log.e("NsdHelper", "mDNS kayıt hatası: $errorCode")
                isRegistered = false
            }

            override fun onServiceUnregistered(serviceInfo: NsdServiceInfo) {
                Log.d("NsdHelper", "mDNS servisi kaydı silindi.")
                isRegistered = false
            }

            override fun onUnregistrationFailed(serviceInfo: NsdServiceInfo, errorCode: Int) {
                Log.e("NsdHelper", "mDNS silme hatası: $errorCode")
            }
        }

        try {
            nsdManager?.registerService(serviceInfo, NsdManager.PROTOCOL_DNS_SD, registrationListener)
        } catch (e: Exception) {
            Log.e("NsdHelper", "mDNS başlatılamadı", e)
        }
    }

    fun unregisterService() {
        if (isRegistered && registrationListener != null) {
            try {
                nsdManager?.unregisterService(registrationListener)
            } catch (e: Exception) {
                Log.e("NsdHelper", "mDNS durdurulamadı", e)
            }
            isRegistered = false
        }
    }
}
