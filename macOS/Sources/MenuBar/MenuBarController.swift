import Cocoa
import SwiftUI
import Combine

public final class MenuBarController: NSObject {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var eventMonitor: Any?
    private let batteryViewModel: BatteryViewModel
    private var cancellables = Set<AnyCancellable>()
    private var fileTransferWindow: NSWindow?
    
    public init(batteryViewModel: BatteryViewModel) {
        self.batteryViewModel = batteryViewModel
        super.init()
        setupStatusItem()
        setupPopover()
        setupBindings()
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "iphone.gen3", accessibilityDescription: "DroidLink")
            button.title = " DroidLink · —"
            button.action = #selector(togglePopover(_:))
            button.target = self
        }
    }
    
    private func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 320, height: 340)
        popover.behavior = .transient
        popover.animates = true
        
        let contentView = BatteryDetailPopoverView(
            viewModel: batteryViewModel,
            onOpenFileTransfer: { [weak self] in
                self?.openFileTransferWindow()
            },
            onOpenSettings: {
                // Ayarlar penceresi
            }
        )
        
        popover.contentViewController = NSHostingController(rootView: contentView)
    }
    
    private func setupBindings() {
        batteryViewModel.$batteryPayload
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateStatusItem()
            }
            .store(in: &cancellables)
        
        batteryViewModel.$connectionStatus
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateStatusItem()
            }
            .store(in: &cancellables)
    }
    
    private func updateStatusItem() {
        guard let button = statusItem.button else { return }
        button.title = " \(batteryViewModel.menuBarTitle)"
        button.image = NSImage(
            systemSymbolName: batteryViewModel.menuBarIconName,
            accessibilityDescription: "Pil Durumu"
        )
    }
    
    @objc public func togglePopover(_ sender: AnyObject?) {
        guard let button = statusItem.button else { return }
        
        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }
    
    public func openFileTransferWindow() {
        popover.performClose(nil)
        
        if fileTransferWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 560, height: 460),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            window.title = "DroidLink — Dosya Transferi"
            window.center()
            window.isReleasedWhenClosed = false
            window.contentView = NSHostingView(rootView: FileTransferView())
            fileTransferWindow = window
        }
        
        fileTransferWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
