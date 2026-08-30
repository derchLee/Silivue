import XCTest
@testable import MonitorEngine

final class MachMemoryDataProviderIntegrationTests: XCTestCase {

    func testReturnsPlausibleMemorySize() {
        let provider = MachMemoryDataProvider()
        let data = provider.readMemoryPages()

        // 现代Mac至少4GB内存
        XCTAssertGreaterThan(data.totalMemory, 4_000_000_000, "Total memory should exceed 4GB on modern Mac")
    }

    func testFreePagesLessThanTotal() {
        let provider = MachMemoryDataProvider()
        let data = provider.readMemoryPages()

        let usedPages = data.activePages + data.wiredPages + data.compressedPages
        XCTAssertGreaterThan(data.totalMemory / data.pageSize, usedPages, "Used pages should be less than total pages")
    }
}
