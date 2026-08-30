import Foundation

public final class ProcessInfoThermalDataProvider: TemperatureDataProvider {
    public init() {}

    public func readTemperatureData() -> TemperatureRawData {
        TemperatureRawData(
            cpuTemperature: nil,
            gpuTemperature: nil,
            fanSpeeds: [],
            thermalState: map(ProcessInfo.processInfo.thermalState)
        )
    }

    private func map(_ state: ProcessInfo.ThermalState) -> SystemThermalState {
        switch state {
        case .nominal: return .nominal
        case .fair: return .fair
        case .serious: return .serious
        case .critical: return .critical
        @unknown default: return .nominal
        }
    }
}
