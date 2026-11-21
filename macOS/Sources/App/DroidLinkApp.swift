import SwiftUI
import AppKit

@main
struct DroidLinkApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarController: MenuBarController?
    private let batteryViewModel = BatteryViewModel()
    private let bonjourDiscovery = BonjourDiscovery()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Dock ikonunu gizle (Menü çubuğu uygulaması)
        NSApp.setActivationPolicy(.accessory)
        
        // Menü çubuğu yöneticisini başlat
        self.menuBarController = MenuBarController(batteryViewModel: batteryViewModel)
        
        // Bonjour keşfini başlat
        self.bonjourDiscovery.startDiscovery()
        
        // Varsayılan bağlantı denemesi (Yerel veya yapılandırılmış cihaz)
        batteryViewModel.connect()
    }
}
