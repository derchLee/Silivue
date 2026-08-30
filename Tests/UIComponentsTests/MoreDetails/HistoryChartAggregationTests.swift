import XCTest
@testable import UIComponents

final class HistoryChartAggregationTests: XCTestCase {
    func testAggregatesValuesIntoThirtySecondAverages() {
        let base = Date(timeIntervalSince1970: 1_800)
        let points = [
            HistoryChartView24h.ChartDataPoint(timestamp: base.addingTimeInterval(2), value: 10),
            HistoryChartView24h.ChartDataPoint(timestamp: base.addingTimeInterval(20), value: 20),
            HistoryChartView24h.ChartDataPoint(timestamp: base.addingTimeInterval(31), value: 40)
        ]

        let result = HistoryChartView24h.ChartDataPoint.aggregate(points)

        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].timestamp, base)
        XCTAssertEqual(result[0].value, 15)
        XCTAssertEqual(result[1].timestamp, base.addingTimeInterval(30))
        XCTAssertEqual(result[1].value, 40)
    }
}
