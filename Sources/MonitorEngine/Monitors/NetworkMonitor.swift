import Combine
import Foundation

public final class NetworkMonitor: SystemMonitor {
    public let displayName = "Network"
    public let monitorID = "network"
    public private(set) var isActive = false

    private let dataProvider: NetworkDataProvider
    private let connectionProvider: NetworkConnectionDataProvider?
    private let timer: RefreshTimer
    private let subject = CurrentValueSubject<AnyMonitorSample?, Never>(nil)
    private var lastData: NetworkInterfaceData?
    private var currentInterval: TimeInterval = 2.0

    public var currentSample: AnyPublisher<AnyMonitorSample, Never> {
        subject.compactMap { $0 }.eraseToAnyPublisher()
    }

    public init(dataProvider: NetworkDataProvider, connectionProvider: NetworkConnectionDataProvider? = nil, timer: RefreshTimer) {
        self.dataProvider = dataProvider
        self.connectionProvider = connectionProvider
        self.timer = timer
        self.timer.onTick = { [weak self] in self?.takeSample() }
    }

    public func start(interval: RefreshInterval) {
        isActive = true
        currentInterval = interval.timeInterval
        timer.onTick = { [weak self] in self?.takeSample() }
        takeSample()
        timer.start(interval: interval.timeInterval)
    }

    public func stop() {
        isActive = false
        timer.onTick = nil
        timer.stop()
        lastData = nil
    }

    public func sample() async throws -> AnyMonitorSample {
        let data = dataProvider.readNetworkData()
        let sample = Self.computeSample(from: data, previous: lastData, interval: currentInterval)
        lastData = data
        return AnyMonitorSample(sample)
    }

    /// 纯函数：从两次连续网络读数计算速率
    public static func computeSample(
        from current: NetworkInterfaceData,
        previous: NetworkInterfaceData?,
        interval: TimeInterval,
        connectionInfo: NetworkConnectionInfo? = nil
    ) -> NetworkSample {
        guard let previous = previous, interval > 0 else {
            // 第一次读数：无法计算速率
            return NetworkSample(
                uploadBytesPerSec: 0,
                downloadBytesPerSec: 0,
                totalUploadBytes: current.obytes,
                totalDownloadBytes: current.ibytes,
                ssid: connectionInfo?.ssid,
                localIP: connectionInfo?.localIP
            )
        }

        let downloadDelta = Double(current.ibytes > previous.ibytes ? current.ibytes - previous.ibytes : 0)
        let uploadDelta = Double(current.obytes > previous.obytes ? current.obytes - previous.obytes : 0)

        return NetworkSample(
            uploadBytesPerSec: uploadDelta / interval,
            downloadBytesPerSec: downloadDelta / interval,
            totalUploadBytes: current.obytes,
            totalDownloadBytes: current.ibytes,
            ssid: connectionInfo?.ssid,
            localIP: connectionInfo?.localIP
        )
    }

    private func takeSample() {
        let data = dataProvider.readNetworkData()
        let connectionInfo = connectionProvider?.readConnectionInfo()
        let sample = Self.computeSample(from: data, previous: lastData, interval: currentInterval, connectionInfo: connectionInfo)
        lastData = data
        subject.send(AnyMonitorSample(sample))
    }
}