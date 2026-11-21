import SwiftUI
import ServiceManagement

public struct SettingsView: View {
    @AppStorage("launchAtLogin") private var launchAtLogin: Bool = false
    @AppStorage("lowBatteryAlert") private var lowBatteryAlert: Bool = true
    @AppStorage("lowBatteryThreshold") private var lowBatteryThreshold: Int = 20
    @AppStorage("fullChargeAlert") private var fullChargeAlert: Bool = true
    @AppStorage("customServerHost") private var customServerHost: String = ""
    @AppStorage("customServerPort") private var customServerPort: Int = 8765
    
    public init() {}
    
    public var body: some View {
        Form {
            Section(header: Text("Genel").fontWeight(.semibold)) {
                Toggle("Girişte Otomatik Başlat", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { newValue in
                        updateLaunchAtLogin(enabled: newValue)
                    }
            }
            
            Section(header: Text("Bildirimler & Pil").fontWeight(.semibold)) {
                Toggle("Düşük Pil Uyarısı Ver", isOn: $lowBatteryAlert)
                if lowBatteryAlert {
                    Picker("Düşük Pil Eşiği", selection: $lowBatteryThreshold) {
                        Text("%10").tag(10)
                        Text("%15").tag(15)
                        Text("%20").tag(20)
                        Text("%25").tag(25)
                    }
                }
                Toggle("Tam Şarj Olduğunda Bildir (%100)", isOn: $fullChargeAlert)
            }
            
            Section(header: Text("Ağ & Bağlantı").fontWeight(.semibold)) {
                TextField("Özel Telefon IP Adresi (Boş = mDNS Otomatik)", text: $customServerHost)
                    .textFieldStyle(.roundedBorder)
                
                HStack {
                    Text("Port:")
                    TextField("Port", value: $customServerPort, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                }
            }
            
            Section(header: Text("Hakkında").fontWeight(.semibold)) {
                HStack {
                    Text("DroidLink macOS")
                    Spacer()
                    Text("v1.0.0 (Intel & Apple Silicon)")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(20)
        .frame(width: 440, height: 360)
    }
    
    private func updateLaunchAtLogin(enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("[Settings] Launch at login error: \(error)")
            }
        }
    }
}
