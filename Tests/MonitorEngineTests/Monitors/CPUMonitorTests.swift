import XCTest
import Combine
@testable import MonitorEngine

final class CPUMonitorTests: XCTestCase {

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
        XCTAssertEqual(monitor.displayName, "CPU")
        XCTAssertEqual(monitor.monitorID, "cpu")
    }

    // MARK: - 启动

    func testStart_setsActive() {
        let monitor = makeMonitor()
        monitor.start(interval: .twoSeconds)
        XCTAssertTrue(monitor.isActive)
        monitor.stop()
    }

    func testStart_startsTimer() {
        let timer = MockRefreshTimer()
        let monitor = makeMonitor(timer: timer)
        monitor.start(interval: .twoSeconds)
        XCTAssertEqual(timer.startCallCount, 1)
        monitor.stop()
    }

    func testStart_passesIntervalToTimer() {
        let timer = MockRefreshTimer()
        let monitor = makeMonitor(timer: timer)
        monitor.start(interval: .fiveSeconds)
        XCTAssertEqual(timer.lastInterval, 5.0)
        monitor.stop()
    }

    func testStart_takesImmediateSample() {
        let dataProvider = MockCPUDataProvider(stubbedTickData: CPUTickData(user: 100, system: 50, idle: 200, nice: 10))
        let monitor = makeMonitor(dataProvider: dataProvider)
        var receivedSamples: [AnyMonitorSample] = []
        monitor.currentSample.sink { receivedSamples.append($0) }.store(in: &cancellables)

        monitor.start(interval: .twoSeconds)

        // 启动时应该立即采样一次
        XCTAssertEqual(receivedSamples.count, 1)
        XCTAssertEqual(dataProvider.callCount, 1)
        monitor.stop()
    }

    // MARK: - 停止

    func testStop_setsInactive() {
        let monitor = makeMonitor()
        monitor.start(interval: .twoSeconds)
        monitor.stop()
        XCTAssertFalse(monitor.isActive)
    }

    func testStop_stopsTimer() {
        let timer = MockRefreshTimer()
        let monitor = makeMonitor(timer: timer)
        monitor.start(interval: .twoSeconds)
        monitor.stop()
        XCTAssertEqual(timer.stopCallCount, 1)
    }

    func testStopsPublishingAfterStop() {
        let dataProvider = MockCPUDataProvider(stubbedTickData: CPUTickData(user: 100, system: 50, idle: 200, nice: 10))
        let timer = MockRefreshTimer()
        let monitor = makeMonitor(dataProvider: dataProvider, timer: timer)
        var receivedSamples: [AnyMonitorSample] = []
        monitor.currentSample.sink { receivedSamples.append($0) }.store(in: &cancellables)

        monitor.start(interval: .twoSeconds)
        let countBeforeStop = receivedSamples.count
        monitor.stop()

        // 停止后手动触发timer，不应该有新sample
        timer.fireTick()
        XCTAssertEqual(receivedSamples.count, countBeforeStop)
    }

    // MARK: - 采样计算

    func testFirstTick_publishesZeroPercent() {
        let dataProvider = MockCPUDataProvider(stubbedTickData: CPUTickData(user: 100, system: 50, idle: 200, nice: 10))
        let timer = MockRefreshTimer()
        let monitor = makeMonitor(dataProvider: dataProvider, timer: timer)
        var receivedSamples: [AnyMonitorSample] = []
        monitor.currentSample.sink { receivedSamples.append($0) }.store(in: &cancellables)

        monitor.start(interval: .twoSeconds)

        // 第一次读数没有前次数据，应该报告0%
        XCTAssertEqual(receivedSamples.first?.cpu?.usagePercent, 0)
    }

    func testSecondTick_computesDelta() {
        let dataProvider = MockCPUDataProvider()
        dataProvider.tickSequence = [
            CPUTickData(user: 100, system: 50, idle: 200, nice: 10),
            CPUTickData(user: 200, system: 100, idle: 350, nice: 20)
        ]
        let timer = MockRefreshTimer()
        let monitor = makeMonitor(dataProvider: dataProvider, timer: timer)
        var receivedSamples: [AnyMonitorSample] = []
        monitor.currentSample.sink { receivedSamples.append($0) }.store(in: &cancellables)

        monitor.start(interval: .twoSeconds)  // 第一次采样
        timer.fireTick()  // 第二次采样

        XCTAssertEqual(receivedSamples.count, 2)
        // delta: user=100, system=50, idle=150, nice=10, total=310
        // usage = (100+50+10)/310 * 100 ≈ 51.61%
        let percent = receivedSamples[1].cpu?.usagePercent ?? -1
        XCTAssertEqual(percent, 51.61, accuracy: 0.01)
    }

    func testPublishesOnEachTick() {
        let dataProvider = MockCPUDataProvider(stubbedTickData: CPUTickData(user: 100, system: 50, idle: 200, nice: 10))
        let timer = MockRefreshTimer()
        let monitor = makeMonitor(dataProvider: dataProvider, timer: timer)
        var receivedSamples: [AnyMonitorSample] = []
        monitor.currentSample.sink { receivedSamples.append($0) }.store(in: &cancellables)

        monitor.start(interval: .twoSeconds)
        timer.fireTick()
        timer.fireTick()

        // start时1次 + 2次tick = 3次
        XCTAssertEqual(receivedSamples.count, 3)
    }

    // MARK: - computeSample 静态纯函数

    func testComputeSample_firstReadingReturnsZero() {
        let current = CPUTickData(user: 100, system: 50, idle: 200, nice: 10)
        let result = CPUMonitor.computeSample(from: current, previous: nil)

        XCTAssertEqual(result.usagePercent, 0)
        XCTAssertEqual(result.idlePercent, 100)
    }

    func testComputeSample_allIdleIsZeroUsage() {
        let previous = CPUTickData(user: 0, system: 0, idle: 100, nice: 0)
        let current = CPUTickData(user: 0, system: 0, idle: 300, nice: 0)
        let result = CPUMonitor.computeSample(from: current, previous: previous)

        XCTAssertEqual(result.usagePercent, 0)
    }

    func testComputeSample_allUserIs100Usage() {
        let previous = CPUTickData(user: 100, system: 0, idle: 0, nice: 0)
        let current = CPUTickData(user: 300, system: 0, idle: 0, nice: 0)
        let result = CPUMonitor.computeSample(from: current, previous: previous)

        XCTAssertEqual(result.usagePercent, 100)
    }

    func testComputeSample_zeroTotalReturnsZero() {
        let previous = CPUTickData(user: 0, system: 0, idle: 0, nice: 0)
        let current = CPUTickData(user: 0, system: 0, idle: 0, nice: 0)
        let result = CPUMonitor.computeSample(from: current, previous: previous)

        XCTAssertEqual(result.usagePercent, 0)
    }

    func testComputeSample_correctBreakdown() {
        let previous = CPUTickData(user: 0, system: 0, idle: 0, nice: 0)
        let current = CPUTickData(user: 50, system: 25, idle: 100, nice: 25)
        let result = CPUMonitor.computeSample(from: current, previous: previous)

        // total = 200, user=50/200=25%, system=25/200=12.5%, idle=50%, nice=12.5%
        XCTAssertEqual(result.userPercent, 25, accuracy: 0.01)
        XCTAssertEqual(result.systemPercent, 12.5, accuracy: 0.01)
        XCTAssertEqual(result.idlePercent, 50, accuracy: 0.01)
        XCTAssertEqual(result.usagePercent, 50, accuracy: 0.01) // user+system+nice
    }

    func testComputeSample_handlesCounterWraparound() {
        let previous = CPUTickData(user: UInt32.max - 4, system: 10, idle: 20, nice: 30)
        let current = CPUTickData(user: 5, system: 20, idle: 30, nice: 40)
        let result = CPUMonitor.computeSample(from: current, previous: previous)

        // Wrapped user delta is 10; every other delta is also 10.
        XCTAssertEqual(result.userPercent, 25, accuracy: 0.01)
        XCTAssertEqual(result.usagePercent, 75, accuracy: 0.01)
    }

    // MARK: - Helper

    private func makeMonitor(dataProvider: MockCPUDataProvider = MockCPUDataProvider(),
                              timer: MockRefreshTimer = MockRefreshTimer()) -> CPUMonitor {
        CPUMonitor(dataProvider: dataProvider, timer: timer)
    }
}
