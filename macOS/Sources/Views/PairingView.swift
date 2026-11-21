import SwiftUI
import Combine

public final class PairingViewModel: ObservableObject {
    @Published public var pairingPin: String = ""
    @Published public var pairingStatus: String = "Eşleşme bekleniyor..."
    @Published public var isPaired: Bool = false
    @Published public var pairedDeviceId: String?
    
    public init() {
        generateNewPin()
    }
    
    public func generateNewPin() {
        self.pairingPin = CryptoSecurity.generateRandomPin()
    }
    
    public func completePairing(deviceId: String, deviceToken: String) {
        _ = KeychainManager.shared.saveToken(deviceToken, forDeviceId: deviceId)
        self.pairedDeviceId = deviceId
        self.isPaired = true
        self.pairingStatus = "Cihaz başarıyla eşleştirildi!"
    }
    
    public func unpair() {
        if let id = pairedDeviceId {
            KeychainManager.shared.deleteToken(forDeviceId: id)
        }
        self.pairedDeviceId = nil
        self.isPaired = false
        generateNewPin()
    }
}

public struct PairingView: View {
    @ObservedObject var viewModel: PairingViewModel
    @Environment(\.dismiss) var dismiss
    
    public init(viewModel: PairingViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 40))
                .foregroundColor(.accentColor)
            
            Text("Cihaz Eşleştirme")
                .font(.system(size: 18, weight: .bold))
            
            Text("Android telefonunuzdaki DroidLink uygulamasından aşağıdaki PIN kodunu onaylayın:")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // PIN Göstergesi
            HStack(spacing: 10) {
                ForEach(Array(viewModel.pairingPin), id: \.self) { char in
                    Text(String(char))
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .frame(width: 38, height: 48)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.08)))
                }
            }
            .padding(.vertical, 8)
            
            Text(viewModel.pairingStatus)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            
            HStack {
                Button("PIN Yenile") {
                    viewModel.generateNewPin()
                }
                .buttonStyle(.bordered)
                
                Button("Kapat") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 360, height: 320)
        .background(VisualEffectBackground())
    }
}
