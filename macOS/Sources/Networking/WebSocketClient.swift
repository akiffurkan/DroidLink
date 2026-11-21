import Foundation

public protocol WebSocketClientDelegate: AnyObject {
    func webSocketDidConnect()
    func webSocketDidDisconnect(error: Error?)
    func webSocketDidReceiveBatteryUpdate(_ payload: BatteryPayload)
    func webSocketDidReceiveRawMessage(_ text: String)
}

public final class WebSocketClient: NSObject, URLSessionWebSocketDelegate {
    private var webSocketTask: URLSessionWebSocketTask?
    private var session: URLSession?
    private var isConnected = false
    private var targetURL: URL?
    private var reconnectTimer: Timer?
    private var heartbeatTimer: Timer?
    
    public weak var delegate: WebSocketClientDelegate?
    
    public override init() {
        super.init()
    }
    
    public func connect(to host: String, port: Int = 8765, token: String? = nil) {
        disconnect()
        
        var urlComponents = URLComponents()
        urlComponents.scheme = "ws"
        urlComponents.host = host
        urlComponents.port = port
        urlComponents.path = "/ws"
        
        if let token = token {
            urlComponents.queryItems = [URLQueryItem(name: "token", value: token)]
        }
        
        guard let url = urlComponents.url else {
            print("[WebSocketClient] Geçersiz URL: \(host):\(port)")
            return
        }
        
        self.targetURL = url
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        self.session = URLSession(configuration: config, delegate: self, delegateQueue: OperationQueue())
        
        let task = session?.webSocketTask(with: url)
        self.webSocketTask = task
        task?.resume()
        
        listenForMessages()
    }
    
    public func disconnect() {
        reconnectTimer?.invalidate()
        reconnectTimer = nil
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
        
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
        session?.invalidateAndCancel()
        session = nil
        
        if isConnected {
            isConnected = false
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.webSocketDidDisconnect(error: nil)
            }
        }
    }
    
    private func listenForMessages() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .failure(let error):
                print("[WebSocketClient] Mesaj alma hatası: \(error)")
                self.handleDisconnection(error: error)
                
            case .success(let message):
                switch message {
                case .string(let text):
                    self.parseIncomingString(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        self.parseIncomingString(text)
                    }
                @unknown default:
                    break
                }
                
                // Dinlemeye devam et
                self.listenForMessages()
            }
        }
    }
    
    private func parseIncomingString(_ text: String) {
        DispatchQueue.main.async {
            self.delegate?.webSocketDidReceiveRawMessage(text)
        }
        
        guard let data = text.data(using: .utf8) else { return }
        let decoder = JSONDecoder()
        
        do {
            let base = try decoder.decode(DroidMessage<BatteryPayload>.self, from: data)
            if base.type == .batteryUpdate {
                DispatchQueue.main.async { [weak self] in
                    self?.delegate?.webSocketDidReceiveBatteryUpdate(base.payload)
                }
            }
        } catch {
            // Farklı bir mesaj türü olabilir
        }
    }
    
    public func send<T: Codable>(type: MessageType, payload: T) {
        let msg = DroidMessage(type: type, payload: payload)
        do {
            let data = try JSONEncoder().encode(msg)
            if let string = String(data: data, encoding: .utf8) {
                let wsMessage = URLSessionWebSocketTask.Message.string(string)
                webSocketTask?.send(wsMessage) { error in
                    if let error = error {
                        print("[WebSocketClient] Gönderim hatası: \(error)")
                    }
                }
            }
        } catch {
            print("[WebSocketClient] JSON encode hatası: \(error)")
        }
    }
    
    private func handleDisconnection(error: Error?) {
        guard isConnected else { return }
        isConnected = false
        
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.webSocketDidDisconnect(error: error)
            self?.scheduleReconnection()
        }
    }
    
    private func scheduleReconnection() {
        reconnectTimer?.invalidate()
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
            guard let self = self, let url = self.targetURL, let host = url.host else { return }
            print("[WebSocketClient] Otomatik yeniden bağlanılıyor...")
            self.connect(to: host, port: url.port ?? 8765)
        }
    }
    
    // MARK: - URLSessionWebSocketDelegate
    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("[WebSocketClient] Bağlantı başarılı!")
        self.isConnected = true
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.webSocketDidConnect()
        }
    }
    
    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("[WebSocketClient] Bağlantı kapandı: \(closeCode)")
        handleDisconnection(error: nil)
    }
}
