import Foundation

public struct BatterySample: Equatable, Codable {
    public let timestamp: Date
    public let monitorID: String = "battery"
    public let chargePercent: Double
    public let isCharging: Bool
    public let healthPercent: Double
    public let cycleCount: Int
    public let timeRemaining: Int
    public let powerSource: String
    public let designCapacity: Int
    public let maxCapacity: Int

    private enum CodingKeys: String, CodingKey {
        case timestamp, chargePercent, isCharging, healthPercent,
             cycleCount, timeRemaining, powerSource, designCapacity, maxCapacity
    }

    public init(timestamp: Date = Date(), chargePercent: Double, isCharging: Bool,
                healthPercent: Double, cycleCount: Int, timeRemaining: Int,
                powerSource: String, designCapacity: Int, maxCapacity: Int) {
        self.timestamp = timestamp
        self.chargePercent = chargePercent
        self.isCharging = isCharging
        self.healthPercent = healthPercent
        self.cycleCount = cycleCount
        self.timeRemaining = timeRemaining
        self.powerSource = powerSource
        self.designCapacity = designCapacity
        self.maxCapacity = maxCapacity
    }
}
