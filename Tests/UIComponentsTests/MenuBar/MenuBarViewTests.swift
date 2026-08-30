import XCTest
import SwiftUI
import MonitorEngine
import DataLayer
@testable import UIComponents

final class MenuBarViewTests: XCTestCase {
    func testCompactModeRenders() {
        let view = CompactMetricView(label: "CPU", value: 45.0, color: MetricColors.cpu)
        XCTAssertNotNil(view)
    }

    func testIconModeRenders() {
        let view = IconMetricView(systemName: "cpu", color: MetricColors.cpu)
        XCTAssertNotNil(view)
    }

    func testNumericModeRenders() {
        let view = NumericMetricView(label: "CPU", value: "45%", color: MetricColors.cpu)
        XCTAssertNotNil(view)
    }

    func testCompactMetricViewClampsValue() {
        let view = CompactMetricView(label: "CPU", value: 150.0, color: MetricColors.cpu)
        XCTAssertNotNil(view)
    }

    func testNumericMetricViewWithBytes() {
        let view = NumericMetricView(label: "RAM", value: "8.00 GB", color: MetricColors.memory)
        XCTAssertNotNil(view)
    }
}
