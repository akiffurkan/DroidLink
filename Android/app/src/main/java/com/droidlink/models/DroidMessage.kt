package com.droidlink.models

import com.google.gson.annotations.SerializedName
import java.util.UUID

enum class MessageType {
    @SerializedName("BATTERY_UPDATE") BATTERY_UPDATE,
    @SerializedName("PAIR_REQUEST") PAIR_REQUEST,
    @SerializedName("PAIR_RESPONSE") PAIR_RESPONSE,
    @SerializedName("FILE_LIST_REQ") FILE_LIST_REQ,
    @SerializedName("FILE_LIST_RESP") FILE_LIST_RESP,
    @SerializedName("FILE_TRANSFER_INIT") FILE_TRANSFER_INIT,
    @SerializedName("FILE_TRANSFER_COMPLETE") FILE_TRANSFER_COMPLETE,
    @SerializedName("HEARTBEAT") HEARTBEAT,
    @SerializedName("DISCONNECT") DISCONNECT
}

data class DroidMessage<T>(
    val protocolVersion: Int = 1,
    val messageId: String = UUID.randomUUID().toString(),
    val type: MessageType,
    val timestamp: Long = System.currentTimeMillis(),
    val payload: T
)
