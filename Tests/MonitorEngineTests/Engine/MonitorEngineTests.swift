import XCTest
import Combine
@testable import MonitorEngine

final class MonitorEngineTests: XCTestCase {

    private var cancellables = Set<AnyCancellable>()

    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }

    // MARK: - 注册

    func testRegister_addsMonitor() {
        let engine = MonitorEngine()
        let monitor = makeCPUMonitor()
        engine.register(monitor)

        XCTAssertTrue(engine.hasMonitor(with: "cpu"))
    }

    func testRegister_multipleMonitors() {
        let engine = MonitorEngine()
        engine.register(makeCPUMonitor())
        engine.register(makeMemoryMonitor())

        XCTAssertTrue(engine.hasMonitor(with: "cpu"))
        XCTAssertTrue(engine.hasMonitor(with: "memory"))
    }

    // MARK: - 启动/停止

    func testStartAll_startsOnlyEnabled() {
        let engine = MonitorEngine()
        let cpuMonitor = makeCPUMonitor()
        let memMonitor = makeMemoryMonitor()
        engine.register(cpuMonitor)
        engine.register(memMonitor)

        engine.startAll(interval: .twoSeconds, enabledMonitors: ["cpu"])

        XCTAssertTrue(cpuMonitor.isActive)
        XCTAssertFalse(memMonitor.isActive)
        engine.stopAll()
    }

    func testStartAll_passesCorrectInterval() {
        let engine = MonitorEngine()
        let timer = MockRefreshTimer()
        let monitor = makeCPUMonitor(timer: timer)
        engine.register(monitor)

        engine.startAll(interval: .fiveSeconds, enabledMonitors: ["cpu"])

        XCTAssertEqual(timer.lastInterval, 5.0)
        engine.stopAll()
    }

    func testStopAll_stopsAllMonitors() {
        let engine = MonitorEngine()
        let cpuMonitor = makeCPUMonitor()
        let memMonitor = makeMemoryMonitor()
        engine.register(cpuMonitor)
        engine.register(memMonitor)

        engine.startAll(interval: .twoSeconds, enabledMonitors: ["cpu", "memory"])
        engine.stopAll()

        XCTAssertFalse(cpuMonitor.isActive)
        XCTAssertFalse(memMonitor.isActive)
    }

    func testStopAll_preservesRecentHistory() {
        let historyUpdated = expectation(description: "CPU history updated")
        let engine = MonitorEngine()
        let timer = MockRefreshTimer()
        let monitor = makeCPUMonitor(timer: timer)
        engine.register(monitor)
        engine.$cpuHistory
            .dropFirst()
            .filter { !$0.isEmpty }
            .prefix(1)
            .sink { _ in historyUpdated.fulfill() }
            .store(in: &cancellables)

        engine.startAll(interval: .twoSeconds, enabledMonitors: ["cpu"])
        wait(for: [historyUpdated], timeout: 1)
        let historyBeforeStop = engine.cpuHistory

        engine.stopAll()

        XCTAssertFalse(historyBeforeStop.isEmpty)
        XCTAssertEqual(engine.cpuHistory, historyBeforeStop)
    }

    // MARK: - 数据发布

    func testCPUSampleUpdates_latestCPU() {
        let expectation = XCTestExpectation(description: "CPU sample received")
        let engine = MonitorEngine()
        let dataProvider = MockCPUDataProvider(stubbedTickData: CPUTickData(user: 100, system: 50, idle: 200, nice: 10))
        let timer = MockRefreshTimer()
        let monitor = CPUMonitor(dataProvider: dataProvider, timer: timer)
        engine.register(monitor)

        engine.$latestCPU
            .compactMap { $0 }
            .sink { _ in expectation.fulfill() }
            .store(in: &cancellables)

        engine.startAll(interval: .twoSeconds, enabledMonitors: ["cpu"])

        wait(for: [expectation], timeout: 2.0)
        XCTAssertNotNil(engine.latestCPU)
        engine.stopAll()
    }

    func testMemorySampleUpdates_latestMemory() {
        let expectation = XCTestExpectation(description: "Memory sample received")
        let engine = MonitorEngine()
        let dataProvider = MockMemoryDataProvider()
        let timer = MockRefreshTimer()
        let monitor = MemoryMonitor(dataProvider: dataProvider, timer: timer)
        engine.register(monitor)

        engine.$latestMemory
            .compactMap { $0 }
            .sink { _ in expectation.fulfill() }
            .store(in: &cancellables)

        engine.startAll(interval: .twoSeconds, enabledMonitors: ["memory"])

        wait(for: [expectation], timeout: 2.0)
        XCTAssertNotNil(engine.latestMemory)
        engine.stopAll()
    }

    func testNetworkSampleUpdates_latestNetwork() {
        let expectation = XCTestExpectation(description: "Network sample received")
        let engine = MonitorEngine()
        let dataProvider = MockNetworkDataProvider()
        let timer = MockRefreshTimer()
        let monitor = NetworkMonitor(dataProvider: dataProvider, timer: timer)
        engine.register(monitor)

        engine.$latestNetwork
            .compactMap { $0 }
            .sink { _ in expectation.fulfill() }
            .store(in: &cancellables)

        engine.startAll(interval: .twoSeconds, enabledMonitors: ["network"])

        wait(for: [expectation], timeout: 2.0)
        XCTAssertNotNil(engine.latestNetwork)
        engine.stopAll()
    }

    func testDiskSampleUpdates_latestDisk() {
        let expectation = XCTestExpectation(description: "Disk sample received")
        let engine = MonitorEngine()
        let dataProvider = MockDiskDataProvider(stubbedVolumes: [
            DiskVolumeData(totalBytes: 500_000, availableBytes: 250_000,
                          volumeName: "Mac", mountPoint: "/")
        ])
        let timer = MockRefreshTimer()
        let monitor = DiskMonitor(dataProvider: dataProvider, timer: timer)
        engine.register(monitor)

        engine.$latestDisk
            .compactMap { $0 }
            .sink { _ in expectation.fulfill() }
            .store(in: &cancellables)

        engine.startAll(interval: .twoSeconds, enabledMonitors: ["disk"])

        wait(for: [expectation], timeout: 2.0)
        XCTAssertNotNil(engine.latestDisk)
        engine.stopAll()
    }

    // MARK: - Helper

    private func makeCPUMonitor(timer: MockRefreshTimer = MockRefreshTimer()) -> CPUMonitor {
        CPUMonitor(dataProvider: MockCPUDataProvider(), timer: timer)
    }

    private func makeMemoryMonitor(timer: MockRefreshTimer = MockRefreshTimer()) -> MemoryMonitor {
        MemoryMonitor(dataProvider: MockMemoryDataProvider(), timer: timer)
    }
}
