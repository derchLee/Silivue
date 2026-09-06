import Foundation

public struct BatteryRawData: Equatable {
    public let chargePercent: Double
    public let isCharging: Bool
    public let healthPercent: Double
    public let cycleCount: Int
    public let timeRemaining: Int
    public let powerSource: String
    public let designCapacity: Int
    public let maxCapacity: Int

    public init(chargePercent: Double, isCharging: Bool, healthPercent: Double,
                cycleCount: Int, timeRemaining: Int, powerSource: String,
                designCapacity: Int, maxCapacity: Int) {
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

public protocol BatteryDataProvider {
    func readBatteryData() -> BatteryRawData
}
