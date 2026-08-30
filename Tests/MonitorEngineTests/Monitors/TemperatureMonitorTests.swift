import XCTest
import Combine
@testable import MonitorEngine

final class TemperatureMonitorTests: XCTestCase {

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
        XCTAssertEqual(monitor.displayName, "Temperature")
        XCTAssertEqual(monitor.monitorID, "temperature")
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
        let dataProvider = MockTemperatureDataProvider()
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
        let dataProvider = MockTemperatureDataProvider()
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
        let dataProvider = MockTemperatureDataProvider()
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

    func testComputeSample_normalTemperature() {
        let data = TemperatureRawData(cpuTemperature: 55.0, gpuTemperature: 50.0,
                                       fanSpeeds: [FanSpeedInfo(currentRPM: 2000, maxRPM: 6000, label: "Fan 0")])
        let sample = TemperatureMonitor.computeSample(from: data)

        XCTAssertEqual(sample.cpuTemperature, 55.0)
        XCTAssertEqual(sample.gpuTemperature, 50.0)
        XCTAssertEqual(sample.fanSpeeds.count, 1)
        XCTAssertFalse(sample.isOverheating)
    }

    func testComputeSample_overheatingCPU() {
        let data = TemperatureRawData(cpuTemperature: 95.0, gpuTemperature: 50.0, fanSpeeds: [])
        let sample = TemperatureMonitor.computeSample(from: data)
        XCTAssertTrue(sample.isOverheating)
    }

    func testComputeSample_overheatingGPU() {
        let data = TemperatureRawData(cpuTemperature: 55.0, gpuTemperature: 100.0, fanSpeeds: [])
        let sample = TemperatureMonitor.computeSample(from: data)
        XCTAssertTrue(sample.isOverheating)
    }

    func testComputeSample_nilTemperatures() {
        let data = TemperatureRawData(cpuTemperature: nil, gpuTemperature: nil, fanSpeeds: [])
        let sample = TemperatureMonitor.computeSample(from: data)
        XCTAssertNil(sample.cpuTemperature)
        XCTAssertNil(sample.gpuTemperature)
        XCTAssertFalse(sample.isOverheating)
    }

    func testComputeSample_noFans() {
        let data = TemperatureRawData(cpuTemperature: 55.0, gpuTemperature: nil, fanSpeeds: [])
        let sample = TemperatureMonitor.computeSample(from: data)
        XCTAssertTrue(sample.fanSpeeds.isEmpty)
    }

    func testComputeSample_multipleFans() {
        let fans = [
            FanSpeedInfo(currentRPM: 2000, maxRPM: 6000, label: "Fan 0"),
            FanSpeedInfo(currentRPM: 1500, maxRPM: 6000, label: "Fan 1")
        ]
        let data = TemperatureRawData(cpuTemperature: 55.0, gpuTemperature: nil, fanSpeeds: fans)
        let sample = TemperatureMonitor.computeSample(from: data)
        XCTAssertEqual(sample.fanSpeeds.count, 2)
        XCTAssertEqual(sample.fanSpeeds[0].currentRPM, 2000)
        XCTAssertEqual(sample.fanSpeeds[1].label, "Fan 1")
    }

    // MARK: - Helper

    private func makeMonitor(dataProvider: MockTemperatureDataProvider = MockTemperatureDataProvider(),
                              timer: MockRefreshTimer = MockRefreshTimer()) -> TemperatureMonitor {
        TemperatureMonitor(dataProvider: dataProvider, timer: timer)
    }
}
