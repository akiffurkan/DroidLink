package com.droidlink.models

import com.google.gson.annotations.SerializedName

enum class ChargingSource {
    @SerializedName("none") NONE,
    @SerializedName("ac") AC,
    @SerializedName("usb") USB,
    @SerializedName("wireless") WIRELESS,
    @SerializedName("unknown") UNKNOWN
}

enum class BatteryHealth {
    @SerializedName("GOOD") GOOD,
    @SerializedName("OVERHEAT") OVERHEAT,
    @SerializedName("DEAD") DEAD,
    @SerializedName("OVER_VOLTAGE") OVER_VOLTAGE,
    @SerializedName("UNKNOWN") UNKNOWN
}

data class BatteryPayload(
    val deviceId: String,
    val deviceName: String,
    val batteryLevel: Int,
    val isCharging: Boolean,
    val chargingSource: ChargingSource,
    val temperature: Double?,
    val health: BatteryHealth?,
    val voltage: Int?,
    val timestamp: Long = System.currentTimeMillis(),
    val protocolVersion: Int = 1
)
