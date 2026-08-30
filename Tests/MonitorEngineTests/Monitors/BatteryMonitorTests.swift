import XCTest
import Combine
@testable import MonitorEngine

final class BatteryMonitorTests: XCTestCase {

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
        XCTAssertEqual(monitor.displayName, "Battery")
        XCTAssertEqual(monitor.monitorID, "battery")
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
        let dataProvider = MockBatteryDataProvider()
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

    func testStop_stopsTimer() {
        let timer = MockRefreshTimer()
        let monitor = makeMonitor(timer: timer)
        monitor.start(interval: .twoSeconds)
        monitor.stop()
        XCTAssertEqual(timer.stopCallCount, 1)
    }

    func testStopsPublishingAfterStop() {
        let dataProvider = MockBatteryDataProvider()
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
        let dataProvider = MockBatteryDataProvider()
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

    func testComputeSample_mapsRawData() {
        let rawData = BatteryRawData(
            chargePercent: 72, isCharging: false, healthPercent: 88,
            cycleCount: 250, timeRemaining: 180, powerSource: "Battery Power",
            designCapacity: 5103, maxCapacity: 4490, amperage: -1200, voltage: 11.8
        )
        let sample = BatteryMonitor.computeSample(from: rawData)

        XCTAssertEqual(sample.chargePercent, 72)
        XCTAssertEqual(sample.isCharging, false)
        XCTAssertEqual(sample.healthPercent, 88)
        XCTAssertEqual(sample.cycleCount, 250)
        XCTAssertEqual(sample.timeRemaining, 180)
        XCTAssertEqual(sample.powerSource, "Battery Power")
        XCTAssertEqual(sample.designCapacity, 5103)
        XCTAssertEqual(sample.maxCapacity, 4490)
    }

    func testComputeSample_preservesChargingState() {
        let charging = BatteryRawData(
            chargePercent: 95, isCharging: true, healthPercent: 100,
            cycleCount: 10, timeRemaining: 15, powerSource: "AC Power",
            designCapacity: 5103, maxCapacity: 5103, amperage: 800, voltage: 12.6
        )
        let result = BatteryMonitor.computeSample(from: charging)
        XCTAssertTrue(result.isCharging)
        XCTAssertEqual(result.powerSource, "AC Power")

        let discharging = BatteryRawData(
            chargePercent: 50, isCharging: false, healthPercent: 90,
            cycleCount: 100, timeRemaining: 300, powerSource: "Battery Power",
            designCapacity: 5103, maxCapacity: 4593, amperage: -1500, voltage: 11.2
        )
        let result2 = BatteryMonitor.computeSample(from: discharging)
        XCTAssertFalse(result2.isCharging)
        XCTAssertEqual(result2.powerSource, "Battery Power")
    }

    // MARK: - Helper

    private func makeMonitor(dataProvider: MockBatteryDataProvider = MockBatteryDataProvider(),
                              timer: MockRefreshTimer = MockRefreshTimer()) -> BatteryMonitor {
        BatteryMonitor(dataProvider: dataProvider, timer: timer)
    }
}
