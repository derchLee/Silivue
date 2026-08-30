import Combine
import Foundation

public final class ProcessMonitor: SystemMonitor {
    public let displayName = "Process"
    public let monitorID = "process"
    public private(set) var isActive = false

    private let dataProvider: ProcessDataProvider
    private let timer: RefreshTimer
    private let topN: Int
    private let subject = CurrentValueSubject<AnyMonitorSample?, Never>(nil)

    public var currentSample: AnyPublisher<AnyMonitorSample, Never> {
        subject.compactMap { $0 }.eraseToAnyPublisher()
    }

    public init(dataProvider: ProcessDataProvider, timer: RefreshTimer, topN: Int = 500) {
        self.dataProvider = dataProvider
        self.timer = timer
        self.topN = topN
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
        let rawData = dataProvider.readProcessList(topN: topN)
        let sample = Self.computeSample(from: rawData, topN: topN)
        return AnyMonitorSample(sample)
    }

    public static func computeSample(from data: ProcessListData, topN: Int = 500) -> ProcessSample {
        let sorted = data.processes.sorted { $0.cpuPercent > $1.cpuPercent }
        let top = Array(sorted.prefix(topN))
        return ProcessSample(topProcesses: top, totalProcessCount: data.totalProcessCount)
    }

    private func takeSample() {
        let rawData = dataProvider.readProcessList(topN: topN)
        let sample = Self.computeSample(from: rawData, topN: topN)
        subject.send(AnyMonitorSample(sample))
    }
}
