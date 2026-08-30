import XCTest
@testable import MonitorEngine

final class IOKitBatteryDataProviderIntegrationTests: XCTestCase {

    func testReadBatteryDataCompletes() {
        let provider = IOKitBatteryDataProvider()
        let data = provider.readBatteryData()

        XCTAssertTrue(data.chargePercent.isFinite)
        XCTAssertTrue(data.healthPercent.isFinite)
        XCTAssertGreaterThanOrEqual(data.chargePercent, 0)
        XCTAssertGreaterThanOrEqual(data.healthPercent, 0)
        XCTAssertGreaterThanOrEqual(data.timeRemaining, -1)
        XCTAssertFalse(data.powerSource.isEmpty)
        XCTAssertGreaterThanOrEqual(data.voltage, 0)
    }
}
