import XCTest
@testable import MonitorEngine

final class MockConformanceTests: XCTestCase {

    // MARK: - CPUDataProvider Mock

    func testMockCPUDataProvider_returnsStubbedData() {
        let stub = CPUTickData(user: 100, system: 50, idle: 200, nice: 10)
        let mock = MockCPUDataProvider(stubbedTickData: stub)

        let result = mock.readCPUTicks()
        XCTAssertEqual(result, stub)
    }

    func testMockCPUDataProvider_incrementsCallCount() {
        let mock = MockCPUDataProvider()
        _ = mock.readCPUTicks()
        _ = mock.readCPUTicks()
        XCTAssertEqual(mock.callCount, 2)
    }

    func testMockCPUDataProvider_supportsSequence() {
        let seq = [
            CPUTickData(user: 100, system: 50, idle: 200, nice: 10),
            CPUTickData(user: 200, system: 100, idle: 350, nice: 20)
        ]
        let mock = MockCPUDataProvider()
        mock.tickSequence = seq

        XCTAssertEqual(mock.readCPUTicks(), seq[0])
        XCTAssertEqual(mock.readCPUTicks(), seq[1])
        XCTAssertEqual(mock.callCount, 2)
    }

    // MARK: - MemoryDataProvider Mock

    func testMockMemoryDataProvider_returnsStubbedData() {
        let stub = MemoryPageData(freePages: 1, activePages: 2, inactivePages: 3,
                                   wiredPages: 4, compressedPages: 5, purgeablePages: 6,
                                   pageSize: 16384, totalMemory: 16_000_000_000, swapUsed: 0)
        let mock = MockMemoryDataProvider(stubbedPageData: stub)

        let result = mock.readMemoryPages()
        XCTAssertEqual(result, stub)
    }

    // MARK: - NetworkDataProvider Mock

    func testMockNetworkDataProvider_returnsStubbedData() {
        let stub = NetworkInterfaceData(ibytes: 1000, obytes: 500, ipackets: 10, opackets: 5)
        let mock = MockNetworkDataProvider(stubbedData: stub)

        let result = mock.readNetworkData()
        XCTAssertEqual(result, stub)
    }

    func testMockNetworkDataProvider_supportsSequence() {
        let seq = [
            NetworkInterfaceData(ibytes: 0, obytes: 0, ipackets: 0, opackets: 0),
            NetworkInterfaceData(ibytes: 1000, obytes: 500, ipackets: 10, opackets: 5)
        ]
        let mock = MockNetworkDataProvider()
        mock.dataSequence = seq

        XCTAssertEqual(mock.readNetworkData(), seq[0])
        XCTAssertEqual(mock.readNetworkData(), seq[1])
    }

    // MARK: - DiskDataProvider Mock

    func testMockDiskDataProvider_returnsStubbedVolumes() {
        let volumes = [
            DiskVolumeData(totalBytes: 500_000_000_000, availableBytes: 250_000_000_000,
                          volumeName: "Mac", mountPoint: "/")
        ]
        let mock = MockDiskDataProvider(stubbedVolumes: volumes)

        let result = mock.readDiskData()
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].volumeName, "Mac")
    }

    // MARK: - RefreshTimer Mock

    func testMockRefreshTimer_fireTickCallsOnTick() {
        let mock = MockRefreshTimer()
        var tickCount = 0
        mock.onTick = { tickCount += 1 }

        mock.fireTick()
        mock.fireTick()

        XCTAssertEqual(tickCount, 2)
    }

    func testMockRefreshTimer_startRecordsInterval() {
        let mock = MockRefreshTimer()
        mock.start(interval: 2.0)

        XCTAssertEqual(mock.startCallCount, 1)
        XCTAssertEqual(mock.lastInterval, 2.0)
    }

    func testMockRefreshTimer_stopIncrementsCount() {
        let mock = MockRefreshTimer()
        mock.stop()

        XCTAssertEqual(mock.stopCallCount, 1)
    }
}
