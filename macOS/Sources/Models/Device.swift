import Foundation

public enum ConnectionStatus: String, Codable {
    case disconnected = "DISCONNECTED"
    case discovering = "DISCOVERING"
    case connecting = "CONNECTING"
    case connected = "CONNECTED"
    case reconnecting = "RECONNECTING"
    case failed = "FAILED"
}

public struct DiscoveredDevice: Identifiable, Hashable {
    public let id: String
    public let name: String
    public let host: String
    public let port: Int
    public let isPaired: Bool
    public var lastSeen: Date

    public init(id: String, name: String, host: String, port: Int, isPaired: Bool = false) {
        self.id = id
        self.name = name
        self.host = host
        self.port = port
        self.isPaired = isPaired
        self.lastSeen = Date()
    }
}
