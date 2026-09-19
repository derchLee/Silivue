import XCTest
@testable import DataLayer
@testable import MonitorEngine

final class MemoryGrowthDetectorTests: XCTestCase {
    func testTriggersOnlyAfterSustainedMeaningfulGrowth() {
        let start = Date()
        let detector = MemoryGrowthDetector()
        let initial = memory(at: start, gibibytes: 6)
        let early = memory(at: start.addingTimeInterval(300), gibibytes: 8)
        let sustained = memory(at: start.addingTimeInterval(600), gibibytes: 8)

        XCTAssertFalse(detector.shouldAlert(for: initial))
        XCTAssertFalse(detector.shouldAlert(for: early))
        XCTAssertTrue(detector.shouldAlert(for: sustained))
    }

    func testResetsWhenMemoryDrops() {
        let start = Date()
        let detector = MemoryGrowthDetector()
        XCTAssertFalse(detector.shouldAlert(for: memory(at: start, gibibytes: 6)))
        XCTAssertFalse(detector.shouldAlert(for: memory(at: start.addingTimeInterval(400), gibibytes: 8)))
        XCTAssertFalse(detector.shouldAlert(for: memory(at: start.addingTimeInterval(500), gibibytes: 6)))
    }

    private func memory(at date: Date, gibibytes: UInt64) -> MemorySample {
        let gibibyte = UInt64(1_024 * 1_024 * 1_024)
        return MemorySample(timestamp: date, usedBytes: gibibytes * gibibyte,
                            totalBytes: 16 * gibibyte, usagePercent: Double(gibibytes) / 16 * 100,
                            pressureLevel: .normal, swapUsedBytes: 0, compressedBytes: 0)
    }
}
