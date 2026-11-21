import Foundation
import Security
import CryptoKit

public final class KeychainManager {
    public static let shared = KeychainManager()
    private let service = "com.droidlink.macos"
    
    private init() {}
    
    public func saveToken(_ token: String, forDeviceId deviceId: String) -> Bool {
        guard let data = token.data(using: .utf8) else { return false }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: deviceId,
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    public func getToken(forDeviceId deviceId: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: deviceId,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess, let data = dataTypeRef as? Data {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
    
    public func deleteToken(forDeviceId deviceId: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: deviceId
        ]
        SecItemDelete(query as CFDictionary)
    }
}

public enum CryptoSecurity {
    public static func sha256(data: Data) -> String {
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
    
    public static func generateRandomPin() -> String {
        var bytes = [UInt8](repeating: 0, count: 3)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        let num = (Int(bytes[0]) << 16) | (Int(bytes[1]) << 8) | Int(bytes[2])
        return String(format: "%06d", num % 1000000)
    }
    
    public static func sanitizeFileName(_ fileName: String) -> String {
        let clean = fileName.components(separatedBy: CharacterSet(charactersIn: "/\\?%*|\"<>:")).joined(separator: "_")
        return clean.replacingOccurrences(of: "..", with: "")
    }
}
