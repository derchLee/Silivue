import XCTest
import Combine
@testable import MonitorEngine

final class ProcessMonitorTests: XCTestCase {

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
        XCTAssertEqual(monitor.displayName, "Process")
        XCTAssertEqual(monitor.monitorID, "process")
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

    func testStart_takesImmediateSample() {
        let dataProvider = MockProcessDataProvider()
        let monitor = makeMonitor(dataProvider: dataProvider)
        var receivedSamples: [AnyMonitorSample] = []
        monitor.currentSample.sink { receivedSamples.append($0) }.store(in: &cancellables)

        monitor.start(interval: .twoSeconds)
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

    func testStopsPublishingAfterStop() {
        let dataProvider = MockProcessDataProvider()
        let timer = MockRefreshTimer()
        let monitor = makeMonitor(dataProvider: dataProvider, timer: timer)
        var receivedSamples: [AnyMonitorSample] = []
        monitor.currentSample.sink { receivedSamples.append($0) }.store(in: &cancellables)

        monitor.start(interval: .twoSeconds)
        let countBeforeStop = receivedSamples.count
        monitor.stop()

        timer.fireTick()
        XCTAssertEqual(receivedSamples.count, countBeforeStop)
    }

    // MARK: - 采样

    func testPublishesOnEachTick() {
        let dataProvider = MockProcessDataProvider()
        let timer = MockRefreshTimer()
        let monitor = makeMonitor(dataProvider: dataProvider, timer: timer)
        var receivedSamples: [AnyMonitorSample] = []
        monitor.currentSample.sink { receivedSamples.append($0) }.store(in: &cancellables)

        monitor.start(interval: .twoSeconds)
        timer.fireTick()
        timer.fireTick()
        XCTAssertEqual(receivedSamples.count, 3)
    }

    // MARK: - computeSample 静态纯函数

    func testComputeSample_sortsByCPU() {
        let data = ProcessListData(
            processes: [
                ProcessInfoItem(pid: 1, name: "low", cpuPercent: 1.0, memoryBytes: 100),
                ProcessInfoItem(pid: 2, name: "high", cpuPercent: 50.0, memoryBytes: 200),
                ProcessInfoItem(pid: 3, name: "mid", cpuPercent: 10.0, memoryBytes: 300),
            ],
            totalProcessCount: 3
        )
        let sample = ProcessMonitor.computeSample(from: data)
        XCTAssertEqual(sample.topProcesses[0].name, "high")
        XCTAssertEqual(sample.topProcesses[1].name, "mid")
        XCTAssertEqual(sample.topProcesses[2].name, "low")
    }

    func testComputeSample_limitsToTopN() {
        var processes: [ProcessInfoItem] = []
        for i in 0..<15 {
            processes.append(ProcessInfoItem(pid: Int32(i), name: "proc\(i)", cpuPercent: Double(15 - i), memoryBytes: 100))
        }
        let data = ProcessListData(processes: processes, totalProcessCount: 15)
        let sample = ProcessMonitor.computeSample(from: data, topN: 10)
        XCTAssertEqual(sample.topProcesses.count, 10)
    }

    func testComputeSample_preservesTotalCount() {
        let data = ProcessListData(processes: [], totalProcessCount: 300)
        let sample = ProcessMonitor.computeSample(from: data)
        XCTAssertEqual(sample.totalProcessCount, 300)
    }

    // MARK: - Helper

    private func makeMonitor(dataProvider: MockProcessDataProvider = MockProcessDataProvider(),
                              timer: MockRefreshTimer = MockRefreshTimer()) -> ProcessMonitor {
        ProcessMonitor(dataProvider: dataProvider, timer: timer)
    }
}
