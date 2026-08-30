import XCTest
@testable import MonitorEngine

final class DarwinNetworkDataProviderIntegrationTests: XCTestCase {

    func testReturnsNonZeroBytes() {
        let provider = DarwinNetworkDataProvider()
        let data = provider.readNetworkData()

        // 至少有loopback接口
        let totalBytes = data.ibytes + data.obytes
        XCTAssertGreaterThan(totalBytes, 0, "At least loopback interface should have some bytes")
    }

    func testBytesIncreaseOverTime() async {
        let provider = DarwinNetworkDataProvider()
        let first = provider.readNetworkData()

        try? await Task.sleep(nanoseconds: 200_000_000)

        let second = provider.readNetworkData()

        // 字节计数应该只增不减
        XCTAssertGreaterThanOrEqual(second.ibytes, first.ibytes, "Download bytes should only increase")
        XCTAssertGreaterThanOrEqual(second.obytes, first.obytes, "Upload bytes should only increase")
    }
}
