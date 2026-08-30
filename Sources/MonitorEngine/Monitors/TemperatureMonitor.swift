import Combine
import Foundation

public final class TemperatureMonitor: SystemMonitor {
    public let displayName = "Temperature"
    public let monitorID = "temperature"
    public private(set) var isActive = false

    private let dataProvider: TemperatureDataProvider
    private let timer: RefreshTimer
    private let subject = CurrentValueSubject<AnyMonitorSample?, Never>(nil)

    public var currentSample: AnyPublisher<AnyMonitorSample, Never> {
        subject.compactMap { $0 }.eraseToAnyPublisher()
    }

    public init(dataProvider: TemperatureDataProvider, timer: RefreshTimer) {
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
        let rawData = dataProvider.readTemperatureData()
        let sample = Self.computeSample(from: rawData)
        return AnyMonitorSample(sample)
    }

    public static func computeSample(from data: TemperatureRawData) -> TemperatureSample {
        let cpuOverheating = (data.cpuTemperature ?? 0) > 90
        let gpuOverheating = (data.gpuTemperature ?? 0) > 95
        return TemperatureSample(
            cpuTemperature: data.cpuTemperature,
            gpuTemperature: data.gpuTemperature,
            fanSpeeds: data.fanSpeeds,
            isOverheating: cpuOverheating || gpuOverheating
        )
    }

    private func takeSample() {
        let rawData = dataProvider.readTemperatureData()
        let sample = Self.computeSample(from: rawData)
        subject.send(AnyMonitorSample(sample))
    }
}
