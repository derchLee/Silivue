import Foundation

public struct NetworkSample: Equatable, Codable {
    public let timestamp: Date
    public let monitorID: String = "network"
    public let uploadBytesPerSec: Double

    private enum CodingKeys: String, CodingKey {
        case timestamp, uploadBytesPerSec, downloadBytesPerSec, totalUploadBytes, totalDownloadBytes, ssid, localIP
    }
    public let downloadBytesPerSec: Double
    public let totalUploadBytes: UInt64
    public let totalDownloadBytes: UInt64
    public let ssid: String?
    public let localIP: String?

    public init(timestamp: Date = Date(), uploadBytesPerSec: Double,
                downloadBytesPerSec: Double, totalUploadBytes: UInt64,
                totalDownloadBytes: UInt64, ssid: String? = nil, localIP: String? = nil) {
        self.timestamp = timestamp
        self.uploadBytesPerSec = uploadBytesPerSec
        self.downloadBytesPerSec = downloadBytesPerSec
        self.totalUploadBytes = totalUploadBytes
        self.totalDownloadBytes = totalDownloadBytes
        self.ssid = ssid
        self.localIP = localIP
    }
}
