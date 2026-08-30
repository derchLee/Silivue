import Combine
import Foundation

public final class DiskMonitor: SystemMonitor {
    public let displayName = "Disk"
    public let monitorID = "disk"
    public private(set) var isActive = false

    private let dataProvider: DiskDataProvider
    private let timer: RefreshTimer
    private let subject = CurrentValueSubject<AnyMonitorSample?, Never>(nil)

    public var currentSample: AnyPublisher<AnyMonitorSample, Never> {
        subject.compactMap { $0 }.eraseToAnyPublisher()
    }

    public init(dataProvider: DiskDataProvider, timer: RefreshTimer) {
        self.dataProvider = dataProvider
        self.timer = timer
        self.timer.onTick = { [weak self] in self?.takeSample() }
    }

    public func start(interval: RefreshInterval) {
        isActive = true
        timer.onTick = { [weak self] in self?.takeSample() }
        takeSample()
        timer.start(interval: interval.timeInterval)
    }

    public func stop() {
        isActive = false
        timer.onTick = nil
        timer.stop()
    }

    public func sample() async throws -> AnyMonitorSample {
        let volumeData = dataProvider.readDiskData()
        let sample = Self.computeSample(from: volumeData)
        return AnyMonitorSample(sample)
    }

    /// 纯函数：从磁盘卷数据计算使用率
    public static func computeSample(from volumes: [DiskVolumeData]) -> DiskSample {
        let volumeInfos = volumes.map { data -> DiskVolumeInfo in
            let usedBytes = data.totalBytes > data.availableBytes ? data.totalBytes - data.availableBytes : 0
            let usagePercent = data.totalBytes > 0
                ? Double(usedBytes) / Double(data.totalBytes) * 100
                : 0

            return DiskVolumeInfo(
                name: data.volumeName,
                mountPoint: data.mountPoint,
                usedBytes: usedBytes,
                totalBytes: data.totalBytes,
                usagePercent: usagePercent
            )
        }
        return DiskSample(volumes: volumeInfos)
    }

    private func takeSample() {
        let volumeData = dataProvider.readDiskData()
        let sample = Self.computeSample(from: volumeData)
        subject.send(AnyMonitorSample(sample))
    }
}