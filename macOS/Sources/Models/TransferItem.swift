import Foundation

public enum TransferDirection: String, Codable {
    case outgoing = "OUTGOING" // Mac -> Phone
    case incoming = "INCOMING" // Phone -> Mac
}

public enum TransferStatus: String, Codable {
    case queued = "QUEUED"
    case transferring = "TRANSFERRING"
    case paused = "PAUSED"
    case completed = "COMPLETED"
    case failed = "FAILED"
    case cancelled = "CANCELLED"
}

public struct TransferItem: Identifiable, Equatable {
    public let id: String
    public let fileName: String
    public let fileSize: Int64
    public var transferredBytes: Int64
    public let direction: TransferDirection
    public var status: TransferStatus
    public var progress: Double {
        guard fileSize > 0 else { return 0 }
        return Double(transferredBytes) / Double(fileSize)
    }
    public var speedBytesPerSecond: Double
    public var estimatedRemainingSeconds: TimeInterval? {
        guard speedBytesPerSecond > 0 else { return nil }
        let remainingBytes = Double(fileSize - transferredBytes)
        return max(0, remainingBytes / speedBytesPerSecond)
    }
    public var errorMessage: String?
    public let startedAt: Date

    public init(
        id: String = UUID().uuidString,
        fileName: String,
        fileSize: Int64,
        direction: TransferDirection,
        transferredBytes: Int64 = 0,
        status: TransferStatus = .queued,
        speedBytesPerSecond: Double = 0
    ) {
        self.id = id
        self.fileName = fileName
        self.fileSize = fileSize
        self.direction = direction
        self.transferredBytes = transferredBytes
        self.status = status
        self.speedBytesPerSecond = speedBytesPerSecond
        self.startedAt = Date()
    }
}
