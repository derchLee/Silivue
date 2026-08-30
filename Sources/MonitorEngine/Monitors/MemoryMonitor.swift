import Combine
import Foundation

public final class MemoryMonitor: SystemMonitor {
    public let displayName = "Memory"
    public let monitorID = "memory"
    public private(set) var isActive = false

    private let dataProvider: MemoryDataProvider
    private let timer: RefreshTimer
    private let subject = CurrentValueSubject<AnyMonitorSample?, Never>(nil)

    public var currentSample: AnyPublisher<AnyMonitorSample, Never> {
        subject.compactMap { $0 }.eraseToAnyPublisher()
    }

    public init(dataProvider: MemoryDataProvider, timer: RefreshTimer) {
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
        let pageData = dataProvider.readMemoryPages()
        let sample = Self.computeSample(from: pageData)
        return AnyMonitorSample(sample)
    }

    /// 纯函数：从内存页数据计算使用率
    public static func computeSample(from data: MemoryPageData) -> MemorySample {
        let usedBytes = (data.activePages + data.wiredPages + data.compressedPages) * data.pageSize
        let usagePercent = data.totalMemory > 0
            ? Double(usedBytes) / Double(data.totalMemory) * 100
            : 0

        // 根据可用页数推断内存压力
        let freeRatio = data.totalMemory > 0
            ? Double(data.freePages * data.pageSize) / Double(data.totalMemory)
            : 1.0
        let pressureLevel: MemoryPressureLevel
        if freeRatio > 0.3 {
            pressureLevel = .normal
        } else if freeRatio > 0.1 {
            pressureLevel = .warning
        } else {
            pressureLevel = .critical
        }

        return MemorySample(
            usedBytes: usedBytes,
            totalBytes: data.totalMemory,
            usagePercent: usagePercent,
            pressureLevel: pressureLevel,
            swapUsedBytes: data.swapUsed,
            compressedBytes: data.compressedPages * data.pageSize
        )
    }

    private func takeSample() {
        let pageData = dataProvider.readMemoryPages()
        let sample = Self.computeSample(from: pageData)
        subject.send(AnyMonitorSample(sample))
    }
}