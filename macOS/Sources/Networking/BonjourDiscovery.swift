import Foundation
import Network

public protocol BonjourDiscoveryDelegate: AnyObject {
    func didDiscoverDevice(_ device: DiscoveredDevice)
    func didLoseDevice(id: String)
}

public final class BonjourDiscovery: ObservableObject {
    private var browser: NWBrowser?
    public weak var delegate: BonjourDiscoveryDelegate?
    
    @Published public private(set) var discoveredDevices: [DiscoveredDevice] = []
    
    public init() {}
    
    public func startDiscovery() {
        let descriptor = NWBrowser.Descriptor.bonjour(type: "_droidlink._tcp", domain: "local.")
        let parameters = NWParameters()
        parameters.includePeerToPeer = true
        
        let browser = NWBrowser(for: descriptor, using: parameters)
        
        browser.browseResultsChangedHandler = { [weak self] results, changes in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.processResults(results)
            }
        }
        
        browser.stateUpdateHandler = { state in
            switch state {
            case .ready:
                print("[BonjourDiscovery] Keşif hazır ve dinliyor.")
            case .failed(let error):
                print("[BonjourDiscovery] Keşif hatası: \(error)")
            case .cancelled:
                print("[BonjourDiscovery] Keşif durduruldu.")
            default:
                break
            }
        }
        
        self.browser = browser
        browser.start(queue: .main)
    }
    
    public func stopDiscovery() {
        browser?.cancel()
        browser = nil
    }
    
    private func processResults(_ results: Set<NWBrowser.Result>) {
        var devices: [DiscoveredDevice] = []
        
        for result in results {
            if case let .service(name, _, _, _) = result.endpoint {
                let id = name
                let host = "auto"
                let port = 8765
                let device = DiscoveredDevice(id: id, name: name, host: host, port: port)
                devices.append(device)
                delegate?.didDiscoverDevice(device)
            }
        }
        
        self.discoveredDevices = devices
    }
}
