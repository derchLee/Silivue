public struct DiskVolumeData: Equatable {
    public let totalBytes: UInt64
    public let availableBytes: UInt64
    public let volumeName: String
    public let mountPoint: String

    public init(totalBytes: UInt64, availableBytes: UInt64, volumeName: String, mountPoint: String) {
        self.totalBytes = totalBytes
        self.availableBytes = availableBytes
        self.volumeName = volumeName
        self.mountPoint = mountPoint
    }
}

public protocol DiskDataProvider {
    func readDiskData() -> [DiskVolumeData]
}
