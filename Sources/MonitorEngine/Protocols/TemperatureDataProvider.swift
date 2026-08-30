import Foundation

public enum SystemThermalState: String, Equatable, Codable {
    case nominal
    case fair
    case serious
    case critical
}

public struct FanSpeedInfo: Equatable, Codable {
    public let currentRPM: Int
    public let maxRPM: Int
    public let label: String

    public init(currentRPM: Int, maxRPM: Int, label: String) {
        self.currentRPM = currentRPM
        self.maxRPM = maxRPM
        self.label = label
    }
}

public struct TemperatureRawData: Equatable {
    public let cpuTemperature: Double?
    public let gpuTemperature: Double?
    public let fanSpeeds: [FanSpeedInfo]
    public let thermalState: SystemThermalState

    public init(cpuTemperature: Double?, gpuTemperature: Double?, fanSpeeds: [FanSpeedInfo],
                thermalState: SystemThermalState = .nominal) {
        self.cpuTemperature = cpuTemperature
        self.gpuTemperature = gpuTemperature
        self.fanSpeeds = fanSpeeds
        self.thermalState = thermalState
    }
}

public protocol TemperatureDataProvider {
    func readTemperatureData() -> TemperatureRawData
}
