import XCTest
@testable import MonitorEngine

final class DiskSampleTests: XCTestCase {

    func testDefaultMonitorID() {
        let sample = DiskSample(volumes: [])
        XCTAssertEqual(sample.monitorID, "disk")
    }

    func testVolumeInfoPercentCalculation() {
        let total: UInt64 = 500 * 1024 * 1024 * 1024  // 500 GB
        let used: UInt64 = 250 * 1024 * 1024 * 1024    // 250 GB
        let expected = Double(used) / Double(total) * 100

        let volume = DiskVolumeInfo(name: "Macintosh HD", mountPoint: "/",
                                    usedBytes: used, totalBytes: total,
                                    usagePercent: expected)
        XCTAssertEqual(volume.usagePercent, 50.0, accuracy: 0.01)
    }

    func testMultipleVolumes() {
        let v1 = DiskVolumeInfo(name: "Macintosh HD", mountPoint: "/",
                                usedBytes: 250_000_000_000, totalBytes: 500_000_000_000,
                                usagePercent: 50)
        let v2 = DiskVolumeInfo(name: "Data", mountPoint: "/Volumes/Data",
                                usedBytes: 800_000_000_000, totalBytes: 1_000_000_000_000,
                                usagePercent: 80)
        let sample = DiskSample(volumes: [v1, v2])
        XCTAssertEqual(sample.volumes.count, 2)
        XCTAssertEqual(sample.volumes[0].name, "Macintosh HD")
        XCTAssertEqual(sample.volumes[1].mountPoint, "/Volumes/Data")
    }

    func testFullDisk() {
        let volume = DiskVolumeInfo(name: "Full", mountPoint: "/Volumes/Full",
                                    usedBytes: 1_000_000, totalBytes: 1_000_000,
                                    usagePercent: 100)
        XCTAssertEqual(volume.usagePercent, 100)
    }
}
