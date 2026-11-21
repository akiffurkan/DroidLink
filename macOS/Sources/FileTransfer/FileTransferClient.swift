import Foundation
import CryptoKit

public struct RemoteFileItem: Identifiable, Codable {
    public var id: String { name }
    public let name: String
    public let size: Int64
    public let mimeType: String
    public let lastModified: Int64
}

public final class FileTransferClient: NSObject, URLSessionTaskDelegate {
    public static let shared = FileTransferClient()
    
    private override init() {
        super.init()
    }
    
    public func fetchRemoteFiles(from host: String, port: Int = 8766, completion: @escaping (Result<[RemoteFileItem], Error>) -> Void) {
        guard let url = URL(string: "http://\(host):\(port)/files") else {
            completion(.failure(URLError(.badURL)))
            return
        }
        
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.success([]))
                return
            }
            
            do {
                let files = try JSONDecoder().decode([RemoteFileItem].self, from: data)
                completion(.success(files))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    public func uploadFile(
        fileURL: URL,
        to host: String,
        port: Int = 8766,
        progressHandler: @escaping (Int64, Int64, Double) -> Void, // transferred, total, speed
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard let url = URL(string: "http://\(host):\(port)/upload") else {
            completion(.failure(URLError(.badURL)))
            return
        }
        
        guard let fileData = try? Data(contentsOf: fileURL) else {
            completion(.failure(NSError(domain: "DroidLink", code: 404, userInfo: [NSLocalizedDescriptionKey: "Dosya okunamadı."])))
            return
        }
        
        let sha256 = CryptoSecurity.sha256(data: fileData)
        let fileName = CryptoSecurity.sanitizeFileName(fileURL.lastPathComponent)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(fileName, forHTTPHeaderField: "X-File-Name")
        request.setValue(sha256, forHTTPHeaderField: "X-File-Sha256")
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        
        let startTime = Date()
        let totalSize = Int64(fileData.count)
        
        let task = URLSession.shared.uploadTask(with: request, from: fileData) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            let elapsed = max(0.1, Date().timeIntervalSince(startTime))
            let speed = Double(totalSize) / elapsed
            progressHandler(totalSize, totalSize, speed)
            
            completion(.success(sha256))
        }
        
        task.resume()
    }
    
    public func downloadFile(
        fileName: String,
        from host: String,
        port: Int = 8766,
        destinationDirectory: URL,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        let safeName = CryptoSecurity.sanitizeFileName(fileName)
        guard let encodedName = safeName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "http://\(host):\(port)/download?file=\(encodedName)") else {
            completion(.failure(URLError(.badURL)))
            return
        }
        
        let destinationURL = destinationDirectory.appendingPathComponent(safeName)
        
        let task = URLSession.shared.downloadTask(with: url) { tempURL, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let tempURL = tempURL else {
                completion(.failure(URLError(.badServerResponse)))
                return
            }
            
            do {
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    try FileManager.default.removeItem(at: destinationURL)
                }
                try FileManager.default.moveItem(at: tempURL, to: destinationURL)
                completion(.success(destinationURL))
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
}
