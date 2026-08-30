import XCTest
@testable import MonitorEngine

final class IOKitBatteryDataProviderIntegrationTests: XCTestCase {
    func testReadBatteryDataReturnsPlausibleValues() {
        let data = IOKitBatteryDataProvider().readBatteryData()

        if data.powerSource == "No Battery" {
            XCTAssertEqual(data.chargePercent, 0)
            XCTAssertEqual(data.healthPercent, 0)
        } else {
            XCTAssertTrue((0...100).contains(data.chargePercent))
            XCTAssertGreaterThan(data.designCapacity, 0)
            XCTAssertGreaterThanOrEqual(data.maxCapacity, 0)
        }
    }
}
