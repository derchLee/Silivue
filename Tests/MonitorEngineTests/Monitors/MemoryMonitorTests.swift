import XCTest
import Combine
@testable import MonitorEngine

final class MemoryMonitorTests: XCTestCase {

    private var cancellables = Set<AnyCancellable>()

    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }

    // MARK: - 初始状态

    func testInit_isInactive() {
        let monitor = makeMonitor()
        XCTAssertFalse(monitor.isActive)
    }

    func testInit_displayNameAndID() {
        let monitor = makeMonitor()
        XCTAssertEqual(monitor.displayName, "Memory")
        XCTAssertEqual(monitor.monitorID, "memory")
    }

    // MARK: - 计算逻辑

    func testComputesUsedBytes() {
        let data = MemoryPageData(
            freePages: 200_000, activePages: 500_000, inactivePages: 300_000,
            wiredPages: 100_000, compressedPages: 50_000, purgeablePages: 10_000,
            pageSize: 16384, totalMemory: 17_179_869_184, swapUsed: 0
        )
        let monitor = makeMonitor(pageData: data)
        var received: [AnyMonitorSample] = []
        monitor.currentSample.sink { received.append($0) }.store(in: &cancellables)
        monitor.start(interval: .twoSeconds)

        let sample = received.first?.memory
        XCTAssertNotNil(sample)
        // used = (active + wired + compressed) * pageSize
        let expectedUsed = UInt64(500_000 + 100_000 + 50_000) * 16384
        XCTAssertEqual(sample?.usedBytes, expectedUsed)
    }

    func testComputesUsagePercent() {
        let data = MemoryPageData(
            freePages: 200_000, activePages: 500_000, inactivePages: 300_000,
            wiredPages: 100_000, compressedPages: 50_000, purgeablePages: 10_000,
            pageSize: 16384, totalMemory: 17_179_869_184, swapUsed: 0
        )
        let monitor = makeMonitor(pageData: data)
        var received: [AnyMonitorSample] = []
        monitor.currentSample.sink { received.append($0) }.store(in: &cancellables)
        monitor.start(interval: .twoSeconds)

        let sample = received.first?.memory
        XCTAssertNotNil(sample)
        // used/total * 100
        let expectedPercent = Double(UInt64(500_000 + 100_000 + 50_000) * 16384) / Double(17_179_869_184) * 100
        XCTAssertEqual(sample?.usagePercent ?? 0, expectedPercent, accuracy: 0.1)
    }

    func testReportsPressureLevel() {
        let data = makeDefaultPageData()
        let monitor = makeMonitor(pageData: data)
        var received: [AnyMonitorSample] = []
        monitor.currentSample.sink { received.append($0) }.store(in: &cancellables)
        monitor.start(interval: .twoSeconds)

        XCTAssertNotNil(received.first?.memory?.pressureLevel)
    }

    func testIncludesSwapAndCompressed() {
        let data = MemoryPageData(
            freePages: 200_000, activePages: 500_000, inactivePages: 300_000,
            wiredPages: 100_000, compressedPages: 819_200, purgeablePages: 10_000,
            pageSize: 16384, totalMemory: 17_179_869_184, swapUsed: 1_073_741_824
        )
        let monitor = makeMonitor(pageData: data)
        var received: [AnyMonitorSample] = []
        monitor.currentSample.sink { received.append($0) }.store(in: &cancellables)
        monitor.start(interval: .twoSeconds)

        let sample = received.first?.memory
        XCTAssertEqual(sample?.swapUsedBytes, 1_073_741_824)
        XCTAssertEqual(sample?.compressedBytes, 819_200 * 16384)
    }

    func testPublishesOnEachTick() {
        let data = makeDefaultPageData()
        let timer = MockRefreshTimer()
        let monitor = makeMonitor(pageData: data, timer: timer)
        var received: [AnyMonitorSample] = []
        monitor.currentSample.sink { received.append($0) }.store(in: &cancellables)

        monitor.start(interval: .twoSeconds)
        timer.fireTick()
        timer.fireTick()

        // start时1次 + 2次tick = 3次
        XCTAssertEqual(received.count, 3)
    }

    // MARK: - Helper

    private func makeMonitor(pageData: MemoryPageData? = nil, timer: MockRefreshTimer? = nil) -> MemoryMonitor {
        let data = pageData ?? makeDefaultPageData()
        let provider = MockMemoryDataProvider(stubbedPageData: data)
        let t = timer ?? MockRefreshTimer()
        return MemoryMonitor(dataProvider: provider, timer: t)
    }

    private func makeDefaultPageData() -> MemoryPageData {
        MemoryPageData(
            freePages: 200_000, activePages: 500_000, inactivePages: 300_000,
            wiredPages: 100_000, compressedPages: 50_000, purgeablePages: 10_000,
            pageSize: 16384, totalMemory: 17_179_869_184, swapUsed: 0
        )
    }
}