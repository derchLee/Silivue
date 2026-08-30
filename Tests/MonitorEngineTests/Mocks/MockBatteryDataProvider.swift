@testable import MonitorEngine

final class MockBatteryDataProvider: BatteryDataProvider {
    var stubbedData: BatteryRawData
    private(set) var callCount = 0

    init(stubbedData: BatteryRawData = BatteryRawData(
        chargePercent: 85, isCharging: true, healthPercent: 95,
        cycleCount: 120, timeRemaining: -1, powerSource: "AC Power",
        designCapacity: 5103, maxCapacity: 4850, amperage: 0, voltage: 12.5)) {
        self.stubbedData = stubbedData
    }

    func readBatteryData() -> BatteryRawData {
        callCount += 1
        return stubbedData
    }
}
