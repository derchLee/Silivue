import Foundation

public struct CPUSample: Equatable, Codable {
    public let timestamp: Date
    public let monitorID: String = "cpu"
    public let usagePercent: Double

    private enum CodingKeys: String, CodingKey {
        case timestamp, usagePercent, userPercent, systemPercent, idlePercent,
             coreCount, frequencyGHz, performanceCoreCount, efficiencyCoreCount
    }
    public let userPercent: Double
    public let systemPercent: Double
    public let idlePercent: Double
    public let coreCount: Int
    public let frequencyGHz: Double?
    public let performanceCoreCount: Int?
    public let efficiencyCoreCount: Int?

    public init(timestamp: Date = Date(), usagePercent: Double, userPercent: Double,
                systemPercent: Double, idlePercent: Double, coreCount: Int,
                frequencyGHz: Double? = nil,
                performanceCoreCount: Int? = nil,
                efficiencyCoreCount: Int? = nil) {
        self.timestamp = timestamp
        self.usagePercent = usagePercent
        self.userPercent = userPercent
        self.systemPercent = systemPercent
        self.idlePercent = idlePercent
        self.coreCount = coreCount
        self.frequencyGHz = frequencyGHz
        self.performanceCoreCount = performanceCoreCount
        self.efficiencyCoreCount = efficiencyCoreCount
    }
}
