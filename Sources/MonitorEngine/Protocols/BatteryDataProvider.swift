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
    public let amperage: Int
    public let voltage: Double

    public init(chargePercent: Double, isCharging: Bool, healthPercent: Double,
                cycleCount: Int, timeRemaining: Int, powerSource: String,
                designCapacity: Int, maxCapacity: Int, amperage: Int, voltage: Double) {
        self.chargePercent = chargePercent
        self.isCharging = isCharging
        self.healthPercent = healthPercent
        self.cycleCount = cycleCount
        self.timeRemaining = timeRemaining
        self.powerSource = powerSource
        self.designCapacity = designCapacity
        self.maxCapacity = maxCapacity
        self.amperage = amperage
        self.voltage = voltage
    }
}

public protocol BatteryDataProvider {
    func readBatteryData() -> BatteryRawData
}
