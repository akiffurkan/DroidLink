import SwiftUI
import UniformTypeIdentifiers

public struct FileTransferView: View {
    @State private var transfers: [TransferItem] = []
    @State private var remoteFiles: [RemoteFileItem] = []
    @State private var isTargetedForDrop: Bool = false
    @State private var selectedTab: Int = 0 // 0: Gönderilenler / Aktif, 1: Telefondaki Dosyalar
    @State private var isLoadingRemoteFiles: Bool = false
    @State private var targetHost: String = "192.168.1.100"
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // Üst Başlık Barı
            HStack {
                Picker("", selection: $selectedTab) {
                    Text("Aktarımlar").tag(0)
                    Text("Telefondaki Dosyalar").tag(1)
                }
                .pickerStyle(.segmented)
                .frame(width: 260)
                
                Spacer()
                
                if selectedTab == 1 {
                    Button(action: refreshRemoteFiles) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(.borderless)
                }
                
                Button(action: selectFileToSend) {
                    Label("Dosya Gönder", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(Color.white.opacity(0.03))
            
            Divider()
            
            if selectedTab == 0 {
                transfersTab
            } else {
                remoteFilesTab
            }
        }
        .frame(minWidth: 540, minHeight: 440)
        .onAppear {
            if let customHost = UserDefaults.standard.string(forKey: "customServerHost"), !customHost.isEmpty {
                self.targetHost = customHost
            }
        }
    }
    
    private var transfersTab: some View {
        VStack(spacing: 0) {
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
            .frame(height: 100)
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
    }
    
    private var remoteFilesTab: some View {
        Group {
            if isLoadingRemoteFiles {
                VStack {
                    Spacer()
                    ProgressView("Telefondan dosya listesi alınıyor...")
                    Spacer()
                }
            } else if remoteFiles.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "folder")
                        .font(.system(size: 36))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("Telefonda DroidLink klasöründe henüz dosya yok")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    Button("Yenile", action: refreshRemoteFiles)
                        .buttonStyle(.bordered)
                    Spacer()
                }
            } else {
                List(remoteFiles) { file in
                    HStack {
                        Image(systemName: fileIcon(for: file.name))
                            .foregroundColor(.accentColor)
                            .font(.system(size: 18))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(file.name)
                                .font(.system(size: 13, weight: .semibold))
                            Text(formatBytes(file.size))
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button("İndir") {
                            downloadFile(file.name)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(.inset)
            }
        }
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
                if item.status == .completed {
                    Text("Tamamlandı ✓")
                        .font(.system(size: 11))
                        .foregroundColor(.green)
                } else if item.status == .failed {
                    Text("Başarısız: \(item.errorMessage ?? "Hata")")
                        .font(.system(size: 11))
                        .foregroundColor(.red)
                } else if let eta = item.estimatedRemainingSeconds {
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
    
    private func refreshRemoteFiles() {
        isLoadingRemoteFiles = true
        FileTransferClient.shared.fetchRemoteFiles(from: targetHost) { result in
            DispatchQueue.main.async {
                self.isLoadingRemoteFiles = false
                switch result {
                case .success(let files):
                    self.remoteFiles = files
                case .failure(let error):
                    print("[FileTransferView] Dosyalar alınamadı: \(error)")
                }
            }
        }
    }
    
    private func selectFileToSend() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        
        if panel.runModal() == .OK {
            for url in panel.urls {
                startUpload(url: url)
            }
        }
    }
    
    private func handleDrop(providers: [NSItemProvider]) {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                guard let data = item as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
                
                DispatchQueue.main.async {
                    self.startUpload(url: url)
                }
            }
        }
    }
    
    private func startUpload(url: URL) {
        let size = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
        var item = TransferItem(
            fileName: url.lastPathComponent,
            fileSize: Int64(size),
            direction: .outgoing,
            transferredBytes: 0,
            status: .transferring
        )
        let itemId = item.id
        transfers.insert(item, at: 0)
        
        FileTransferClient.shared.uploadFile(
            fileURL: url,
            to: targetHost,
            progressHandler: { transferred, total, speed in
                DispatchQueue.main.async {
                    if let index = self.transfers.firstIndex(where: { $0.id == itemId }) {
                        self.transfers[index].transferredBytes = transferred
                        self.transfers[index].speedBytesPerSecond = speed
                    }
                }
            },
            completion: { result in
                DispatchQueue.main.async {
                    if let index = self.transfers.firstIndex(where: { $0.id == itemId }) {
                        switch result {
                        case .success:
                            self.transfers[index].status = .completed
                            self.transfers[index].transferredBytes = Int64(size)
                        case .failure(let error):
                            self.transfers[index].status = .failed
                            self.transfers[index].errorMessage = error.localizedDescription
                        }
                    }
                }
            }
        )
    }
    
    private func downloadFile(_ fileName: String) {
        guard let downloadsDir = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first else { return }
        
        let item = TransferItem(
            fileName: fileName,
            fileSize: 0,
            direction: .incoming,
            status: .transferring
        )
        let itemId = item.id
        transfers.insert(item, at: 0)
        selectedTab = 0
        
        FileTransferClient.shared.downloadFile(fileName: fileName, from: targetHost, destinationDirectory: downloadsDir) { result in
            DispatchQueue.main.async {
                if let index = self.transfers.firstIndex(where: { $0.id == itemId }) {
                    switch result {
                    case .success(let fileURL):
                        self.transfers[index].status = .completed
                        let size = (try? fileURL.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
                        self.transfers[index].transferredBytes = Int64(size)
                    case .failure(let error):
                        self.transfers[index].status = .failed
                        self.transfers[index].errorMessage = error.localizedDescription
                    }
                }
            }
        }
    }
    
    private func fileIcon(for name: String) -> String {
        let ext = name.components(separatedBy: ".").last?.lowercased() ?? ""
        switch ext {
        case "jpg", "jpeg", "png", "heic": return "photo"
        case "mp4", "mov": return "film"
        case "mp3", "m4a", "wav": return "music.note"
        case "pdf": return "doc.richtext"
        case "zip", "tar", "gz": return "archivebox"
        default: return "doc"
        }
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
