import Foundation

public struct TemperatureSample: Equatable, Codable {
    public let timestamp: Date
    public let monitorID: String = "temperature"
    public let cpuTemperature: Double?
    public let gpuTemperature: Double?
    public let fanSpeeds: [FanSpeedInfo]
    public let thermalState: SystemThermalState
    public let isOverheating: Bool

    private enum CodingKeys: String, CodingKey {
        case timestamp, cpuTemperature, gpuTemperature, fanSpeeds, thermalState, isOverheating
    }

    public init(timestamp: Date = Date(), cpuTemperature: Double?, gpuTemperature: Double?,
                fanSpeeds: [FanSpeedInfo], thermalState: SystemThermalState = .nominal,
                isOverheating: Bool) {
        self.timestamp = timestamp
        self.cpuTemperature = cpuTemperature
        self.gpuTemperature = gpuTemperature
        self.fanSpeeds = fanSpeeds
        self.thermalState = thermalState
        self.isOverheating = isOverheating
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        cpuTemperature = try container.decodeIfPresent(Double.self, forKey: .cpuTemperature)
        gpuTemperature = try container.decodeIfPresent(Double.self, forKey: .gpuTemperature)
        fanSpeeds = try container.decode([FanSpeedInfo].self, forKey: .fanSpeeds)
        thermalState = try container.decodeIfPresent(SystemThermalState.self, forKey: .thermalState) ?? .nominal
        isOverheating = try container.decode(Bool.self, forKey: .isOverheating)
    }
}
