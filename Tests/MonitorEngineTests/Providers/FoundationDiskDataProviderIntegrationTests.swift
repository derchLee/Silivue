import XCTest
@testable import MonitorEngine

final class FoundationDiskDataProviderIntegrationTests: XCTestCase {

    func testReturnsRootVolume() {
        let provider = FoundationDiskDataProvider()
        let volumes = provider.readDiskData()

        XCTAssertGreaterThan(volumes.count, 0, "Should return at least one volume")

        let rootVolume = volumes.first { $0.mountPoint == "/" }
        XCTAssertNotNil(rootVolume, "Root volume should exist")
    }

    func testTotalExceedsAvailable() {
        let provider = FoundationDiskDataProvider()
        let volumes = provider.readDiskData()

        for volume in volumes {
            XCTAssertGreaterThanOrEqual(volume.totalBytes, volume.availableBytes,
                                         "Total should be >= available for volume \(volume.volumeName)")
        }
    }
}
