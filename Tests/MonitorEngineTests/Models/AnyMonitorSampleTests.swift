import XCTest
@testable import MonitorEngine

final class AnyMonitorSampleTests: XCTestCase {

    func testTypeErasurePreservesCPU() {
        let cpu = CPUSample(usagePercent: 45, userPercent: 30,
                            systemPercent: 15, idlePercent: 55, coreCount: 8)
        let anySample = AnyMonitorSample(cpu)

        XCTAssertEqual(anySample.monitorID, "cpu")
        XCTAssertEqual(anySample.cpu?.usagePercent, 45)
    }

    func testTypeErasurePreservesMemory() {
        let memory = MemorySample(usedBytes: 8_000, totalBytes: 16_000,
                                  usagePercent: 50, pressureLevel: .normal,
                                  swapUsedBytes: 0, compressedBytes: 0)
        let anySample = AnyMonitorSample(memory)

        XCTAssertEqual(anySample.monitorID, "memory")
        XCTAssertEqual(anySample.memory?.usagePercent, 50)
    }

    func testTypeErasurePreservesNetwork() {
        let network = NetworkSample(uploadBytesPerSec: 100, downloadBytesPerSec: 200,
                                    totalUploadBytes: 1000, totalDownloadBytes: 2000)
        let anySample = AnyMonitorSample(network)

        XCTAssertEqual(anySample.monitorID, "network")
        XCTAssertEqual(anySample.network?.uploadBytesPerSec, 100)
    }

    func testTypeErasurePreservesDisk() {
        let disk = DiskSample(volumes: [])
        let anySample = AnyMonitorSample(disk)

        XCTAssertEqual(anySample.monitorID, "disk")
        XCTAssertNotNil(anySample.disk)
    }

    func testReturnsNilForWrongType() {
        let cpu = CPUSample(usagePercent: 45, userPercent: 30,
                            systemPercent: 15, idlePercent: 55, coreCount: 8)
        let anySample = AnyMonitorSample(cpu)

        XCTAssertNil(anySample.memory)
        XCTAssertNil(anySample.network)
        XCTAssertNil(anySample.disk)
    }

    func testTimestampPreserved() {
        let specificDate = Date(timeIntervalSince1970: 1000)
        let cpu = CPUSample(timestamp: specificDate, usagePercent: 45,
                            userPercent: 30, systemPercent: 15,
                            idlePercent: 55, coreCount: 8)
        let anySample = AnyMonitorSample(cpu)

        XCTAssertEqual(anySample.timestamp.timeIntervalSince1970, 1000, accuracy: 0.01)
    }
}
