import XCTest
@testable import MonitorEngine

final class CPUSampleTests: XCTestCase {

    // MARK: - monitorID

    func testDefaultMonitorID() {
        let sample = CPUSample(usagePercent: 45, userPercent: 30,
                               systemPercent: 15, idlePercent: 55, coreCount: 8)
        XCTAssertEqual(sample.monitorID, "cpu")
    }

    // MARK: - Equatable

    func testEqualSamples() {
        let sample1 = CPUSample(timestamp: .distantPast, usagePercent: 50,
                                userPercent: 30, systemPercent: 20, idlePercent: 50,
                                coreCount: 8, frequencyGHz: 3.2)
        let sample2 = CPUSample(timestamp: .distantPast, usagePercent: 50,
                                userPercent: 30, systemPercent: 20, idlePercent: 50,
                                coreCount: 8, frequencyGHz: 3.2)
        XCTAssertEqual(sample1, sample2)
    }

    func testDifferentSamples() {
        let sample1 = CPUSample(usagePercent: 50, userPercent: 30,
                                systemPercent: 20, idlePercent: 50, coreCount: 8)
        let sample2 = CPUSample(usagePercent: 60, userPercent: 30,
                                systemPercent: 20, idlePercent: 50, coreCount: 8)
        XCTAssertNotEqual(sample1, sample2)
    }

    // MARK: - Default values

    func testDefaultFrequencyIsNil() {
        let sample = CPUSample(usagePercent: 0, userPercent: 0,
                               systemPercent: 0, idlePercent: 100, coreCount: 4)
        XCTAssertNil(sample.frequencyGHz)
    }

    func testUsagePercentRange() {
        // 0% usage
        let idle = CPUSample(usagePercent: 0, userPercent: 0,
                             systemPercent: 0, idlePercent: 100, coreCount: 4)
        XCTAssertEqual(idle.usagePercent, 0)

        // 100% usage
        let full = CPUSample(usagePercent: 100, userPercent: 80,
                             systemPercent: 20, idlePercent: 0, coreCount: 4)
        XCTAssertEqual(full.usagePercent, 100)
    }
}
