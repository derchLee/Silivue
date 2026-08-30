import Foundation

public struct ProcessSample: Equatable, Codable {
    public let timestamp: Date
    public let monitorID: String = "process"
    public let topProcesses: [ProcessInfoItem]
    public let totalProcessCount: Int

    private enum CodingKeys: String, CodingKey {
        case timestamp, topProcesses, totalProcessCount
    }

    public init(timestamp: Date = Date(), topProcesses: [ProcessInfoItem], totalProcessCount: Int) {
        self.timestamp = timestamp
        self.topProcesses = topProcesses
        self.totalProcessCount = totalProcessCount
    }
}
