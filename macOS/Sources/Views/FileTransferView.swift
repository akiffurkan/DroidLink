import SwiftUI
import UniformTypeIdentifiers

public struct FileTransferView: View {
    @State private var transfers: [TransferItem] = []
    @State private var isTargetedForDrop: Bool = false
    @State private var searchText: String = ""
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // Üst Başlık Barı
            HStack {
                Text("Dosya Transferi")
                    .font(.system(size: 16, weight: .bold))
                Spacer()
                
                Button(action: selectFileToSend) {
                    Label("Dosya Gönder", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(Color.white.opacity(0.03))
            
            Divider()
            
            // Sürükle Bırak Alanı
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [6]))
                    .foregroundColor(isTargetedForDrop ? .accentColor : .secondary.opacity(0.4))
                    .background(isTargetedForDrop ? Color.accentColor.opacity(0.08) : Color.clear)
                
                VStack(spacing: 8) {
                    Image(systemName: "arrow.down.doc")
                        .font(.system(size: 30))
                        .foregroundColor(isTargetedForDrop ? .accentColor : .secondary)
                    Text("Telefona göndermek için dosyaları buraya sürükleyin")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .frame(height: 110)
            .padding()
            .onDrop(of: [.fileURL], isTargeted: $isTargetedForDrop) { providers in
                handleDrop(providers: providers)
                return true
            }
            
            // Aktarım Listesi
            if transfers.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "tray")
                        .font(.system(size: 36))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("Aktif veya geçmiş dosya aktarımı yok")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else {
                List {
                    ForEach(transfers) { item in
                        transferRow(item)
                    }
                }
                .listStyle(.inset)
            }
        }
        .frame(minWidth: 500, minHeight: 400)
    }
    
    private func transferRow(_ item: TransferItem) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: item.direction == .outgoing ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                    .foregroundColor(item.direction == .outgoing ? .blue : .green)
                
                Text(item.fileName)
                    .font(.system(size: 13, weight: .semibold))
                
                Spacer()
                
                Text(formatBytes(item.transferredBytes) + " / " + formatBytes(item.fileSize))
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: item.progress)
                .progressViewStyle(.linear)
            
            HStack {
                if let eta = item.estimatedRemainingSeconds {
                    Text(String(format: "Kalan: %.0f sn (%.1f MB/s)", eta, item.speedBytesPerSecond / 1_000_000))
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                } else {
                    Text(item.status.rawValue)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
        }
        .padding(.vertical, 4)
    }
    
    private func selectFileToSend() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        
        if panel.runModal() == .OK {
            for url in panel.urls {
                addOutgoingFile(url: url)
            }
        }
    }
    
    private func handleDrop(providers: [NSItemProvider]) {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                guard let data = item as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
                
                DispatchQueue.main.async {
                    self.addOutgoingFile(url: url)
                }
            }
        }
    }
    
    private func addOutgoingFile(url: URL) {
        let size = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
        let item = TransferItem(
            fileName: url.lastPathComponent,
            fileSize: Int64(size),
            direction: .outgoing,
            transferredBytes: 0,
            status: .queued
        )
        transfers.insert(item, at: 0)
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
