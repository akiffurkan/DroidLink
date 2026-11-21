import Foundation
import Combine

public final class BatteryViewModel: ObservableObject, WebSocketClientDelegate {
    @Published public var connectionStatus: ConnectionStatus = .disconnected
    @Published public var batteryPayload: BatteryPayload?
    @Published public var lastUpdated: Date?
    @Published public var targetHost: String = "192.168.1.100" // Kullanıcı ayarlarından veya mDNS'ten
    @Published public var isAutoReconnectEnabled: Bool = true
    
    private let client: WebSocketClient
    
    public init(client: WebSocketClient = WebSocketClient()) {
        self.client = client
        self.client.delegate = self
    }
    
    public var menuBarTitle: String {
        switch connectionStatus {
        case .connected:
            if let payload = batteryPayload {
                let bolt = payload.isCharging ? "⚡" : ""
                return "\(payload.batteryLevel)% \(bolt)".trimmingCharacters(in: .whitespaces)
            } else {
                return "Bağlı"
            }
        case .connecting, .reconnecting:
            return "Bağlanıyor..."
        case .discovering:
            return "Aranıyor..."
        case .disconnected, .failed:
            return "—"
        }
    }
    
    public var menuBarIconName: String {
        guard connectionStatus == .connected, let payload = batteryPayload else {
            return "battery.slash"
        }
        
        let level = payload.batteryLevel
        let isCharging = payload.isCharging
        
        if isCharging {
            return "battery.100.bolt"
        }
        
        switch level {
        case 0...15:
            return "battery.0"
        case 16...35:
            return "battery.25"
        case 36...65:
            return "battery.50"
        case 66...85:
            return "battery.75"
        default:
            return "battery.100"
        }
    }
    
    public func connect(to host: String? = nil) {
        let hostToUse = host ?? targetHost
        self.targetHost = hostToUse
        self.connectionStatus = .connecting
        client.connect(to: hostToUse)
    }
    
    public func disconnect() {
        self.connectionStatus = .disconnected
        client.disconnect()
    }
    
    // MARK: - WebSocketClientDelegate
    public func webSocketDidConnect() {
        self.connectionStatus = .connected
    }
    
    public func webSocketDidDisconnect(error: Error?) {
        self.connectionStatus = isAutoReconnectEnabled ? .reconnecting : .disconnected
    }
    
    public func webSocketDidReceiveBatteryUpdate(_ payload: BatteryPayload) {
        self.batteryPayload = payload
        self.lastUpdated = Date()
    }
    
    public func webSocketDidReceiveRawMessage(_ text: String) {
        // İsteğe bağlı debug logu
    }
}
