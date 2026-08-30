import Combine
import Foundation

public final class CPUMonitor: SystemMonitor {
    public let displayName = "CPU"
    public let monitorID = "cpu"
    public private(set) var isActive = false

    private let dataProvider: CPUDataProvider
    private let timer: RefreshTimer
    private let subject = CurrentValueSubject<AnyMonitorSample?, Never>(nil)
    private var lastTickData: CPUTickData?

    public var currentSample: AnyPublisher<AnyMonitorSample, Never> {
        subject.compactMap { $0 }.eraseToAnyPublisher()
    }

    public init(dataProvider: CPUDataProvider, timer: RefreshTimer) {
        self.dataProvider = dataProvider
        self.timer = timer
        self.timer.onTick = { [weak self] in self?.takeSample() }
    }

    public func start(interval: RefreshInterval) {
        isActive = true
        timer.onTick = { [weak self] in self?.takeSample() }
        takeSample() // 立即首次采样
        timer.start(interval: interval.timeInterval)
    }

    public func stop() {
        isActive = false
        timer.onTick = nil
        timer.stop()
        lastTickData = nil
    }

    public func sample() async throws -> AnyMonitorSample {
        let tickData = dataProvider.readCPUTicks()
        let sample = Self.computeSample(from: tickData, previous: lastTickData)
        lastTickData = tickData
        return AnyMonitorSample(sample)
    }

    // MARK: - Private

    private func takeSample() {
        let tickData = dataProvider.readCPUTicks()
        let sample = Self.computeSample(from: tickData, previous: lastTickData)
        lastTickData = tickData
        subject.send(AnyMonitorSample(sample))
    }

    /// 纯函数：从两次连续tick读数计算CPU使用率
    /// CPU使用率 = (delta_user + delta_system + delta_nice) / delta_total
    public static func computeSample(
        from current: CPUTickData,
        previous: CPUTickData?,
        coreCount: Int = ProcessInfo.processInfo.processorCount
    ) -> CPUSample {
        guard let previous = previous else {
            // 第一次读数：无法计算增量，报告0%
            return CPUSample(
                usagePercent: 0,
                userPercent: 0,
                systemPercent: 0,
                idlePercent: 100,
                coreCount: coreCount,
                frequencyGHz: current.frequencyGHz,
                performanceCoreCount: current.performanceCoreCount,
                efficiencyCoreCount: current.efficiencyCoreCount
            )
        }

        // host_cpu_load_info exposes 32-bit counters. They eventually wrap, so
        // use wrapping subtraction to preserve the elapsed tick count.
        let dUser = Double(current.user &- previous.user)
        let dSystem = Double(current.system &- previous.system)
        let dIdle = Double(current.idle &- previous.idle)
        let dNice = Double(current.nice &- previous.nice)
        let dTotal = dUser + dSystem + dIdle + dNice

        guard dTotal > 0 else {
            return CPUSample(
                usagePercent: 0,
                userPercent: 0,
                systemPercent: 0,
                idlePercent: 100,
                coreCount: coreCount,
                frequencyGHz: current.frequencyGHz,
                performanceCoreCount: current.performanceCoreCount,
                efficiencyCoreCount: current.efficiencyCoreCount
            )
        }

        return CPUSample(
            usagePercent: ((dUser + dSystem + dNice) / dTotal) * 100,
            userPercent: (dUser / dTotal) * 100,
            systemPercent: (dSystem / dTotal) * 100,
            idlePercent: (dIdle / dTotal) * 100,
            coreCount: coreCount,
            frequencyGHz: current.frequencyGHz,
            performanceCoreCount: current.performanceCoreCount,
            efficiencyCoreCount: current.efficiencyCoreCount
        )
    }
}
