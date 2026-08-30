@testable import MonitorEngine

final class MockMemoryDataProvider: MemoryDataProvider {
    var stubbedPageData: MemoryPageData
    private(set) var callCount = 0

    init(stubbedPageData: MemoryPageData = MemoryPageData(
        freePages: 2_000_000, activePages: 2_000_000, inactivePages: 1_000_000,
        wiredPages: 500_000, compressedPages: 100_000, purgeablePages: 50_000,
        pageSize: 16384, totalMemory: 16_384_000_000, swapUsed: 0)) {
        self.stubbedPageData = stubbedPageData
    }

    func readMemoryPages() -> MemoryPageData {
        callCount += 1
        return stubbedPageData
    }
}
