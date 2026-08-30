import XCTest
@testable import MonitorEngine

final class NetworkSampleTests: XCTestCase {

    func testDefaultMonitorID() {
        let sample = NetworkSample(uploadBytesPerSec: 0, downloadBytesPerSec: 0,
                                   totalUploadBytes: 0, totalDownloadBytes: 0)
        XCTAssertEqual(sample.monitorID, "network")
    }

    func testUploadDownloadSpeeds() {
        let sample = NetworkSample(uploadBytesPerSec: 1024,
                                   downloadBytesPerSec: 2048,
                                   totalUploadBytes: 10_000,
                                   totalDownloadBytes: 50_000)
        XCTAssertEqual(sample.uploadBytesPerSec, 1024)
        XCTAssertEqual(sample.downloadBytesPerSec, 2048)
    }

    func testCumulativeBytes() {
        let sample = NetworkSample(uploadBytesPerSec: 100,
                                   downloadBytesPerSec: 200,
                                   totalUploadBytes: 1_000_000,
                                   totalDownloadBytes: 5_000_000)
        XCTAssertEqual(sample.totalUploadBytes, 1_000_000)
        XCTAssertEqual(sample.totalDownloadBytes, 5_000_000)
    }
}
