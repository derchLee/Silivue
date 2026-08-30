import XCTest
@testable import MonitorEngine

final class ProcessInfoThermalDataProviderTests: XCTestCase {
    func testReadTemperatureDataUsesPublicThermalStateWithoutPrivateSensorValues() {
        let data = ProcessInfoThermalDataProvider().readTemperatureData()

        XCTAssertNil(data.cpuTemperature)
        XCTAssertNil(data.gpuTemperature)
        XCTAssertTrue(data.fanSpeeds.isEmpty)
    }
}
