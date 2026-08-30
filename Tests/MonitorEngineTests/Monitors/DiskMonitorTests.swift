import XCTest
import Combine
@testable import MonitorEngine

final class DiskMonitorTests: XCTestCase {

    private var cancellables = Set<AnyCancellable>()

    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }

    func testInit_isInactive() {
        let monitor = makeMonitor()
        XCTAssertFalse(monitor.isActive)
    }

    func testInit_displayNameAndID() {
        let monitor = makeMonitor()
        XCTAssertEqual(monitor.displayName, "Disk")
        XCTAssertEqual(monitor.monitorID, "disk")
    }

    func testReportsVolumeUsage() {
        let volumes = [
            DiskVolumeData(totalBytes: 500_000_000_000, availableBytes: 250_000_000_000,
                          volumeName: "Mac", mountPoint: "/")
        ]
        let monitor = makeMonitor(volumes: volumes)
        var received: [AnyMonitorSample] = []
        monitor.currentSample.sink { received.append($0) }.store(in: &cancellables)

        monitor.start(interval: .twoSeconds)

        let sample = received.first?.disk
        XCTAssertNotNil(sample)
        XCTAssertEqual(sample?.volumes.count, 1)
        XCTAssertEqual(sample?.volumes.first?.name, "Mac")
    }

    func testComputesPercentCorrectly() {
        let volumes = [
            DiskVolumeData(totalBytes: 1_000_000, availableBytes: 200_000,
                          volumeName: "Test", mountPoint: "/")
        ]
        let monitor = makeMonitor(volumes: volumes)
        var received: [AnyMonitorSample] = []
        monitor.currentSample.sink { received.append($0) }.store(in: &cancellables)

        monitor.start(interval: .twoSeconds)

        let volume = received.first?.disk?.volumes.first
        // used = total - available = 800_000, percent = 80%
        XCTAssertEqual(volume?.usagePercent ?? -1, 80.0, accuracy: 0.01)
    }

    func testHandlesMultipleVolumes() {
        let volumes = [
            DiskVolumeData(totalBytes: 500_000, availableBytes: 250_000,
                          volumeName: "Mac", mountPoint: "/"),
            DiskVolumeData(totalBytes: 1_000_000, availableBytes: 100_000,
                          volumeName: "Data", mountPoint: "/Volumes/Data")
        ]
        let monitor = makeMonitor(volumes: volumes)
        var received: [AnyMonitorSample] = []
        monitor.currentSample.sink { received.append($0) }.store(in: &cancellables)

        monitor.start(interval: .twoSeconds)

        let sample = received.first?.disk
        XCTAssertEqual(sample?.volumes.count, 2)
        XCTAssertEqual(sample?.volumes[0].usagePercent ?? -1, 50.0, accuracy: 0.01)
        XCTAssertEqual(sample?.volumes[1].usagePercent ?? -1, 90.0, accuracy: 0.01)
    }

    func testHandlesZeroAvailableSpace() {
        let volumes = [
            DiskVolumeData(totalBytes: 1_000_000, availableBytes: 0,
                          volumeName: "Full", mountPoint: "/Volumes/Full")
        ]
        let monitor = makeMonitor(volumes: volumes)
        var received: [AnyMonitorSample] = []
        monitor.currentSample.sink { received.append($0) }.store(in: &cancellables)

        monitor.start(interval: .twoSeconds)

        let volume = received.first?.disk?.volumes.first
        XCTAssertEqual(volume?.usagePercent ?? -1, 100.0, accuracy: 0.01)
    }

    func testPublishesOnEachTick() {
        let volumes = [DiskVolumeData(totalBytes: 1_000_000, availableBytes: 500_000,
                                       volumeName: "Mac", mountPoint: "/")]
        let timer = MockRefreshTimer()
        let monitor = makeMonitor(volumes: volumes, timer: timer)
        var received: [AnyMonitorSample] = []
        monitor.currentSample.sink { received.append($0) }.store(in: &cancellables)

        monitor.start(interval: .twoSeconds)
        timer.fireTick()
        timer.fireTick()

        XCTAssertEqual(received.count, 3)
    }

    // MARK: - Helper

    private func makeMonitor(volumes: [DiskVolumeData] = [],
                              timer: MockRefreshTimer = MockRefreshTimer()) -> DiskMonitor {
        let provider = MockDiskDataProvider(stubbedVolumes: volumes)
        return DiskMonitor(dataProvider: provider, timer: timer)
    }
}