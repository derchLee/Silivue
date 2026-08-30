@testable import MonitorEngine

final class MockTemperatureDataProvider: TemperatureDataProvider {
    var stubbedData: TemperatureRawData
    private(set) var callCount = 0

    init(stubbedData: TemperatureRawData = TemperatureRawData(
        cpuTemperature: 55.0,
        gpuTemperature: 50.0,
        fanSpeeds: [FanSpeedInfo(currentRPM: 2000, maxRPM: 6000, label: "Fan 0")])) {
        self.stubbedData = stubbedData
    }

    func readTemperatureData() -> TemperatureRawData {
        callCount += 1
        return stubbedData
    }
}
