import XCTest
import SwiftUI
@testable import UIComponents

final class MetricColorsTests: XCTestCase {
    func testCPUColorExists() {
        XCTAssertNotNil(MetricColors.cpu)
    }

    func testMemoryColorExists() {
        XCTAssertNotNil(MetricColors.memory)
    }

    func testDiskColorExists() {
        XCTAssertNotNil(MetricColors.disk)
    }

    func testNetworkUpColorExists() {
        XCTAssertNotNil(MetricColors.networkUp)
    }

    func testNetworkDownColorExists() {
        XCTAssertNotNil(MetricColors.networkDown)
    }

    func testWarningColorExists() {
        XCTAssertNotNil(MetricColors.warning)
    }

    func testDangerColorExists() {
        XCTAssertNotNil(MetricColors.danger)
    }
}
