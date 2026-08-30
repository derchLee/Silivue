import Foundation

public struct MemorySample: Equatable, Codable {
    public let timestamp: Date
    public let monitorID: String = "memory"
    public let usedBytes: UInt64

    private enum CodingKeys: String, CodingKey {
        case timestamp, usedBytes, totalBytes, usagePercent, pressureLevel, swapUsedBytes, compressedBytes
    }
    public let totalBytes: UInt64
    public let usagePercent: Double
    public let pressureLevel: MemoryPressureLevel
    public let swapUsedBytes: UInt64
    public let compressedBytes: UInt64

    public init(timestamp: Date = Date(), usedBytes: UInt64, totalBytes: UInt64,
                usagePercent: Double, pressureLevel: MemoryPressureLevel,
                swapUsedBytes: UInt64, compressedBytes: UInt64) {
        self.timestamp = timestamp
        self.usedBytes = usedBytes
        self.totalBytes = totalBytes
        self.usagePercent = usagePercent
        self.pressureLevel = pressureLevel
        self.swapUsedBytes = swapUsedBytes
        self.compressedBytes = compressedBytes
    }
}
