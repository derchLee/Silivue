import Combine
import Foundation

public final class BatteryMonitor: SystemMonitor {
    public let displayName = "Battery"
    public let monitorID = "battery"
    public private(set) var isActive = false

    private let dataProvider: BatteryDataProvider
    private let timer: RefreshTimer
    private let subject = CurrentValueSubject<AnyMonitorSample?, Never>(nil)

    public var currentSample: AnyPublisher<AnyMonitorSample, Never> {
        subject.compactMap { $0 }.eraseToAnyPublisher()
    }

    public init(dataProvider: BatteryDataProvider, timer: RefreshTimer) {
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
        let rawData = dataProvider.readBatteryData()
        let sample = Self.computeSample(from: rawData)
        return AnyMonitorSample(sample)
    }

    public static func computeSample(from data: BatteryRawData) -> BatterySample {
        BatterySample(
            chargePercent: data.chargePercent,
            isCharging: data.isCharging,
            healthPercent: data.healthPercent,
            cycleCount: data.cycleCount,
            timeRemaining: data.timeRemaining,
            powerSource: data.powerSource,
            designCapacity: data.designCapacity,
            maxCapacity: data.maxCapacity
        )
    }

    private func takeSample() {
        let rawData = dataProvider.readBatteryData()
        let sample = Self.computeSample(from: rawData)
        subject.send(AnyMonitorSample(sample))
    }
}
