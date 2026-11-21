import Foundation

public enum MessageType: String, Codable {
    case batteryUpdate = "BATTERY_UPDATE"
    case pairRequest = "PAIR_REQUEST"
    case pairResponse = "PAIR_RESPONSE"
    case fileListReq = "FILE_LIST_REQ"
    case fileListResp = "FILE_LIST_RESP"
    case fileTransferInit = "FILE_TRANSFER_INIT"
    case fileTransferComplete = "FILE_TRANSFER_COMPLETE"
    case heartbeat = "HEARTBEAT"
    case disconnect = "DISCONNECT"
}

public struct DroidMessage<T: Codable>: Codable {
    public let protocolVersion: Int
    public let messageId: String
    public let type: MessageType
    public let timestamp: Int64
    public let payload: T

    public init(type: MessageType, payload: T, protocolVersion: Int = 1) {
        self.protocolVersion = protocolVersion
        self.messageId = UUID().uuidString
        self.type = type
        self.timestamp = Int64(Date().timeIntervalSince1970 * 1000)
        self.payload = payload
    }
}
