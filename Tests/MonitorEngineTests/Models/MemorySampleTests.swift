import XCTest
@testable import MonitorEngine

final class MemorySampleTests: XCTestCase {

    func testDefaultMonitorID() {
        let sample = MemorySample(usedBytes: 8 * 1024 * 1024 * 1024,
                                  totalBytes: 16 * 1024 * 1024 * 1024,
                                  usagePercent: 50, pressureLevel: .normal,
                                  swapUsedBytes: 0, compressedBytes: 0)
        XCTAssertEqual(sample.monitorID, "memory")
    }

    func testUsagePercentCalculation() {
        let used: UInt64 = 8 * 1024 * 1024 * 1024  // 8 GB
        let total: UInt64 = 16 * 1024 * 1024 * 1024 // 16 GB
        let expected = Double(used) / Double(total) * 100

        let sample = MemorySample(usedBytes: used, totalBytes: total,
                                  usagePercent: expected, pressureLevel: .normal,
                                  swapUsedBytes: 0, compressedBytes: 0)
        XCTAssertEqual(sample.usagePercent, 50.0, accuracy: 0.01)
    }

    func testPressureLevelRawValues() {
        XCTAssertEqual(MemoryPressureLevel.normal.rawValue, 1)
        XCTAssertEqual(MemoryPressureLevel.warning.rawValue, 2)
        XCTAssertEqual(MemoryPressureLevel.critical.rawValue, 4)
    }

    func testSwapAndCompressedIncluded() {
        let sample = MemorySample(usedBytes: 8_000_000_000,
                                  totalBytes: 16_000_000_000,
                                  usagePercent: 50, pressureLevel: .warning,
                                  swapUsedBytes: 2_000_000_000,
                                  compressedBytes: 500_000_000)
        XCTAssertEqual(sample.swapUsedBytes, 2_000_000_000)
        XCTAssertEqual(sample.compressedBytes, 500_000_000)
        XCTAssertEqual(sample.pressureLevel, .warning)
    }
}
