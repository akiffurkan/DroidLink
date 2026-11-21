import SwiftUI

public struct BatteryDetailPopoverView: View {
    @ObservedObject var viewModel: BatteryViewModel
    var onOpenFileTransfer: () -> Void = {}
    var onOpenSettings: () -> Void = {}
    
    public init(
        viewModel: BatteryViewModel,
        onOpenFileTransfer: @escaping () -> Void = {},
        onOpenSettings: @escaping () -> Void = {}
    ) {
        self.viewModel = viewModel
        self.onOpenFileTransfer = onOpenFileTransfer
        self.onOpenSettings = onOpenSettings
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            // Başlık ve Cihaz Bilgisi
            HStack {
                Image(systemName: "iphone.gen3")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.accentColor)
                
                Text(viewModel.batteryPayload?.deviceName ?? "Samsung Galaxy A04e")
                    .font(.system(size: 14, weight: .bold))
                
                Spacer()
                
                statusBadge
            }
            
            Divider()
                .opacity(0.3)
            
            // Büyük Pil ve Şarj Göstergesi
            HStack(spacing: 20) {
                batteryGraphic(level: viewModel.batteryPayload?.batteryLevel ?? 0, isCharging: viewModel.batteryPayload?.isCharging ?? false)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(viewModel.batteryPayload?.batteryLevel ?? 0)")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                        Text("%")
                            .font(.system(size: 20, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                        
                        if viewModel.batteryPayload?.isCharging == true {
                            Image(systemName: "bolt.fill")
                                .foregroundColor(.yellow)
                                .font(.system(size: 20))
                                .padding(.leading, 4)
                        }
                    }
                    
                    Text(chargingSourceText)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.vertical, 4)
            
            // Detay Bilgileri Tablosu
            VStack(spacing: 8) {
                if let temp = viewModel.batteryPayload?.temperature {
                    detailRow(title: "Sıcaklık", value: String(format: "%.1f °C", temp), icon: "thermometer.medium")
                }
                if let health = viewModel.batteryPayload?.health {
                    detailRow(title: "Pil Sağlığı", value: health.rawValue, icon: "heart.fill")
                }
                if let voltage = viewModel.batteryPayload?.voltage {
                    detailRow(title: "Voltaj", value: "\(voltage) mV", icon: "bolt.badge.clock")
                }
                
                detailRow(
                    title: "Son Güncelleme",
                    value: formattedLastUpdated,
                    icon: "clock.arrow.circlepath"
                )
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.04)))
            
            // Aksiyon Butonları
            HStack(spacing: 10) {
                Button(action: {
                    if viewModel.connectionStatus == .connected {
                        viewModel.disconnect()
                    } else {
                        viewModel.connect()
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: viewModel.connectionStatus == .connected ? "stop.circle" : "arrow.clockwise")
                        Text(viewModel.connectionStatus == .connected ? "Bağlantıyı Kes" : "Yeniden Bağlan")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
                
                Button(action: onOpenFileTransfer) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.left.arrow.right")
                        Text("Dosya Transferi")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
            }
        }
        .padding(18)
        .frame(width: 320)
        .background(
            VisualEffectBackground()
        )
    }
    
    private var statusBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            Text(statusText)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(Capsule().fill(Color.white.opacity(0.06)))
    }
    
    private var statusColor: Color {
        switch viewModel.connectionStatus {
        case .connected: return .green
        case .connecting, .reconnecting, .discovering: return .yellow
        case .disconnected, .failed: return .red
        }
    }
    
    private var statusText: String {
        switch viewModel.connectionStatus {
        case .connected: return "Bağlı"
        case .connecting: return "Bağlanıyor"
        case .reconnecting: return "Yeniden Bağlanıyor"
        case .discovering: return "Cihaz Aranıyor"
        case .disconnected: return "Bağlantı Yok"
        case .failed: return "Başarısız"
        }
    }
    
    private var chargingSourceText: String {
        guard let payload = viewModel.batteryPayload else { return "Veri bekleniyor" }
        if !payload.isCharging {
            return "Pilden Kullanılıyor"
        }
        switch payload.chargingSource {
        case .usb: return "USB ile Şarj Ediliyor"
        case .ac: return "AC Priz ile Hızlı Şarj"
        case .wireless: return "Kablosuz Şarj"
        default: return "Şarj Ediliyor"
        }
    }
    
    private var formattedLastUpdated: String {
        guard let date = viewModel.lastUpdated else { return "Henüz alınmadı" }
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
    
    @ViewBuilder
    private func batteryGraphic(level: Int, isCharging: Bool) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.primary.opacity(0.4), lineWidth: 2)
                .frame(width: 52, height: 28)
            
            // Pil ucu
            RoundedRectangle(cornerRadius: 1.5)
                .fill(Color.primary.opacity(0.4))
                .frame(width: 3, height: 10)
                .offset(x: 28)
            
            // Pil doluluk seviyesi
            let fillWidth = max(0, min(46, 46.0 * Double(level) / 100.0))
            HStack {
                RoundedRectangle(cornerRadius: 5)
                    .fill(batteryColor(for: level))
                    .frame(width: fillWidth, height: 22)
                Spacer(minLength: 0)
            }
            .frame(width: 46)
        }
    }
    
    private func batteryColor(for level: Int) -> Color {
        if level <= 20 {
            return .red
        } else if level <= 40 {
            return .yellow
        } else {
            return .green
        }
    }
    
    private func detailRow(title: String, value: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .frame(width: 14)
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .semibold))
        }
    }
}

// macOS Translucent Glass Arka Planı (AppKit NSVisualEffectView köprüsü)
public struct VisualEffectBackground: NSViewRepresentable {
    public init() {}
    public func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.blendingMode = .behindWindow
        view.state = .active
        view.material = .popover
        return view
    }
    public func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
