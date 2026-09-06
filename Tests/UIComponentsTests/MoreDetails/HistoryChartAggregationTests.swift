import XCTest
@testable import UIComponents

final class HistoryChartAggregationTests: XCTestCase {
    func testMissingBucketsBreakLineWithoutAddingValues() {
        let points = [0, 30, 90, 120, 300].map {
            HistoryChartView24h.ChartDataPoint(timestamp: Date(timeIntervalSince1970: Double($0)), value: 10)
        }
        let result = HistoryChartView24h.ChartDataPoint.aggregate(points.reversed())
        XCTAssertEqual(result.map(\.segmentID), [0, 0, 1, 1, 2])
        XCTAssertEqual(result.map(\.isIsolated), [false, false, false, false, true])
        XCTAssertEqual(result.map(\.timestamp), points.map(\.timestamp))
    }

    func testEmptyAndSinglePointHistory() {
        XCTAssertTrue(HistoryChartView24h.ChartDataPoint.aggregate([]).isEmpty)
        let result = HistoryChartView24h.ChartDataPoint.aggregate([
            .init(timestamp: Date(timeIntervalSince1970: 0), value: 7)
        ])
        XCTAssertEqual(result.first?.segmentID, 0)
        XCTAssertEqual(result.first?.isIsolated, true)
    }

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
        XCTAssertEqual(result.map(\.segmentID), [0, 0])
        XCTAssertEqual(result.map(\.isIsolated), [false, false])
    }
}
