package com.droidlink

import com.droidlink.models.BatteryHealth
import com.droidlink.models.BatteryPayload
import com.droidlink.models.ChargingSource
import com.droidlink.models.DroidMessage
import com.droidlink.models.MessageType
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class ProtocolTest {
    private val gson = Gson()

    @Test
    fun testBatteryPayloadSerialization() {
        val payload = BatteryPayload(
            deviceId = "test-device-123",
            deviceName = "Samsung Galaxy A04e",
            batteryLevel = 84,
            isCharging = true,
            chargingSource = ChargingSource.USB,
            temperature = 29.5,
            health = BatteryHealth.GOOD,
            voltage = 4120
        )

        val message = DroidMessage(
            type = MessageType.BATTERY_UPDATE,
            payload = payload
        )

        val json = gson.toJson(message)
        assertTrue(json.contains("BATTERY_UPDATE"))
        assertTrue(json.contains("Samsung Galaxy A04e"))
        assertTrue(json.contains("\"batteryLevel\":84"))

        val typeToken = object : TypeToken<DroidMessage<BatteryPayload>>() {}.type
        val decoded: DroidMessage<BatteryPayload> = gson.fromJson(json, typeToken)

        assertEquals(MessageType.BATTERY_UPDATE, decoded.type)
        assertEquals(84, decoded.payload.batteryLevel)
        assertEquals(true, decoded.payload.isCharging)
        assertEquals(ChargingSource.USB, decoded.payload.chargingSource)
    }
}
