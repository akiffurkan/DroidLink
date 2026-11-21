package com.droidlink.security

import android.content.Context
import android.content.SharedPreferences
import java.security.SecureRandom
import java.util.UUID

class PairingManager(context: Context) {

    private val prefs: SharedPreferences = context.getSharedPreferences("droidlink_security", Context.MODE_PRIVATE)

    fun getOrGenerateDeviceId(): String {
        var id = prefs.getString("device_id", null)
        if (id == null) {
            id = UUID.randomUUID().toString()
            prefs.edit().putString("device_id", id).apply()
        }
        return id
    }

    fun isDevicePaired(macDeviceId: String): Boolean {
        return prefs.getString("token_$macDeviceId", null) != null
    }

    fun savePairedToken(macDeviceId: String, token: String) {
        prefs.edit().putString("token_$macDeviceId", token).apply()
    }

    fun removePairing(macDeviceId: String) {
        prefs.edit().remove("token_$macDeviceId").apply()
    }

    fun generatePairingPin(): String {
        val random = SecureRandom()
        val pin = random.nextInt(900000) + 100000
        return pin.toString()
    }

    fun generateAuthToken(): String {
        return UUID.randomUUID().toString() + "-" + System.currentTimeMillis()
    }
}
