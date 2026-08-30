import Foundation

public struct DiskSample: Equatable, Codable {
    public let timestamp: Date
    public let monitorID: String = "disk"
    public let volumes: [DiskVolumeInfo]

    private enum CodingKeys: String, CodingKey {
        case timestamp, volumes
    }

    public init(timestamp: Date = Date(), volumes: [DiskVolumeInfo]) {
        self.timestamp = timestamp
        self.volumes = volumes
    }
}

public struct DiskVolumeInfo: Equatable, Codable, Identifiable {
    public var id: String { mountPoint }
    public let name: String
    public let mountPoint: String
    public let usedBytes: UInt64
    public let totalBytes: UInt64
    public let usagePercent: Double

    public init(name: String, mountPoint: String, usedBytes: UInt64,
                totalBytes: UInt64, usagePercent: Double) {
        self.name = name
        self.mountPoint = mountPoint
        self.usedBytes = usedBytes
        self.totalBytes = totalBytes
        self.usagePercent = usagePercent
    }
}
