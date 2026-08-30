import XCTest
import Combine
@testable import MonitorEngine

final class NetworkMonitorTests: XCTestCase {

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
        XCTAssertEqual(monitor.displayName, "Network")
        XCTAssertEqual(monitor.monitorID, "network")
    }

    func testFirstReading_isZeroSpeed() {
        let provider = MockNetworkDataProvider(stubbedData: NetworkInterfaceData(
            ibytes: 1000, obytes: 500, ipackets: 10, opackets: 5))
        let monitor = makeMonitor(provider: provider)
        var received: [AnyMonitorSample] = []
        monitor.currentSample.sink { received.append($0) }.store(in: &cancellables)

        monitor.start(interval: .twoSeconds)

        let sample = received.first?.network
        XCTAssertNotNil(sample)
        XCTAssertEqual(sample?.uploadBytesPerSec, 0)
        XCTAssertEqual(sample?.downloadBytesPerSec, 0)
    }

    func testComputesUploadSpeed() {
        let provider = MockNetworkDataProvider()
        provider.dataSequence = [
            NetworkInterfaceData(ibytes: 1000, obytes: 500, ipackets: 10, opackets: 5),
            NetworkInterfaceData(ibytes: 2000, obytes: 1500, ipackets: 20, opackets: 10)
        ]
        let timer = MockRefreshTimer()
        let monitor = makeMonitor(provider: provider, timer: timer)
        var received: [AnyMonitorSample] = []
        monitor.currentSample.sink { received.append($0) }.store(in: &cancellables)

        monitor.start(interval: .twoSeconds)
        timer.fireTick()

        // upload delta = 1500 - 500 = 1000 bytes, interval = 2s → 500 bytes/sec
        let sample = received[1].network
        XCTAssertNotNil(sample)
        XCTAssertEqual(sample?.uploadBytesPerSec ?? -1, 500, accuracy: 0.01)
    }

    func testComputesDownloadSpeed() {
        let provider = MockNetworkDataProvider()
        provider.dataSequence = [
            NetworkInterfaceData(ibytes: 1000, obytes: 500, ipackets: 10, opackets: 5),
            NetworkInterfaceData(ibytes: 5000, obytes: 1500, ipackets: 20, opackets: 10)
        ]
        let timer = MockRefreshTimer()
        let monitor = makeMonitor(provider: provider, timer: timer)
        var received: [AnyMonitorSample] = []
        monitor.currentSample.sink { received.append($0) }.store(in: &cancellables)

        monitor.start(interval: .twoSeconds)
        timer.fireTick()

        // download delta = 5000 - 1000 = 4000 bytes, interval = 2s → 2000 bytes/sec
        let sample = received[1].network
        XCTAssertEqual(sample?.downloadBytesPerSec ?? -1, 2000, accuracy: 0.01)
    }

    func testTracksCumulativeBytes() {
        let provider = MockNetworkDataProvider(stubbedData: NetworkInterfaceData(
            ibytes: 5000, obytes: 2000, ipackets: 50, opackets: 30))
        let monitor = makeMonitor(provider: provider)
        var received: [AnyMonitorSample] = []
        monitor.currentSample.sink { received.append($0) }.store(in: &cancellables)

        monitor.start(interval: .twoSeconds)

        let sample = received.first?.network
        XCTAssertEqual(sample?.totalDownloadBytes, 5000)
        XCTAssertEqual(sample?.totalUploadBytes, 2000)
    }

    func testSpeedDependsOnInterval() {
        let provider = MockNetworkDataProvider()
        provider.dataSequence = [
            NetworkInterfaceData(ibytes: 0, obytes: 0, ipackets: 0, opackets: 0),
            NetworkInterfaceData(ibytes: 1000, obytes: 500, ipackets: 10, opackets: 5),
            NetworkInterfaceData(ibytes: 3000, obytes: 1500, ipackets: 30, opackets: 15)
        ]
        let timer = MockRefreshTimer()
        let monitor = makeMonitor(provider: provider, timer: timer)
        var received: [AnyMonitorSample] = []
        monitor.currentSample.sink { received.append($0) }.store(in: &cancellables)

        monitor.start(interval: .twoSeconds)
        timer.fireTick()

        // delta: 1000/2s download, 500/2s upload
        XCTAssertEqual(received[1].network?.downloadBytesPerSec ?? -1, 500, accuracy: 0.01)
        XCTAssertEqual(received[1].network?.uploadBytesPerSec ?? -1, 250, accuracy: 0.01)
    }

    func testPublishesOnEachTick() {
        let provider = MockNetworkDataProvider(stubbedData: NetworkInterfaceData(
            ibytes: 100, obytes: 50, ipackets: 1, opackets: 1))
        let timer = MockRefreshTimer()
        let monitor = makeMonitor(provider: provider, timer: timer)
        var received: [AnyMonitorSample] = []
        monitor.currentSample.sink { received.append($0) }.store(in: &cancellables)

        monitor.start(interval: .twoSeconds)
        timer.fireTick()
        timer.fireTick()

        XCTAssertEqual(received.count, 3)
    }

    // MARK: - Helper

    private func makeMonitor(provider: MockNetworkDataProvider = MockNetworkDataProvider(),
                              timer: MockRefreshTimer = MockRefreshTimer()) -> NetworkMonitor {
        NetworkMonitor(dataProvider: provider, connectionProvider: nil, timer: timer)
    }
}
