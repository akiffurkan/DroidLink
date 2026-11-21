import Foundation

public enum ChargingSource: String, Codable {
    case none = "none"
    case ac = "ac"
    case usb = "usb"
    case wireless = "wireless"
    case unknown = "unknown"
}

public enum BatteryHealth: String, Codable {
    case good = "GOOD"
    case overheat = "OVERHEAT"
    case dead = "DEAD"
    case overVoltage = "OVER_VOLTAGE"
    case unknown = "UNKNOWN"
}

public struct BatteryPayload: Codable, Equatable {
    public let deviceId: String
    public let deviceName: String
    public let batteryLevel: Int
    public let isCharging: Bool
    public let chargingSource: ChargingSource
    public let temperature: Double?
    public let health: BatteryHealth?
    public let voltage: Int?
    public let timestamp: Int64
    public let protocolVersion: Int

    public init(
        deviceId: String,
        deviceName: String,
        batteryLevel: Int,
        isCharging: Bool,
        chargingSource: ChargingSource,
        temperature: Double? = nil,
        health: BatteryHealth? = nil,
        voltage: Int? = nil,
        timestamp: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        protocolVersion: Int = 1
    ) {
        self.deviceId = deviceId
        self.deviceName = deviceName
        self.batteryLevel = max(0, min(100, batteryLevel))
        self.isCharging = isCharging
        self.chargingSource = chargingSource
        self.temperature = temperature
        self.health = health
        self.voltage = voltage
        self.timestamp = timestamp
        self.protocolVersion = protocolVersion
    }
}
