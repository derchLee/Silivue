import Foundation

public struct TemperatureSample: Equatable, Codable {
    public let timestamp: Date
    public let monitorID: String = "temperature"
    public let cpuTemperature: Double?
    public let gpuTemperature: Double?
    public let fanSpeeds: [FanSpeedInfo]
    public let isOverheating: Bool

    private enum CodingKeys: String, CodingKey {
        case timestamp, cpuTemperature, gpuTemperature, fanSpeeds, isOverheating
    }

    public init(timestamp: Date = Date(), cpuTemperature: Double?, gpuTemperature: Double?,
                fanSpeeds: [FanSpeedInfo], isOverheating: Bool) {
        self.timestamp = timestamp
        self.cpuTemperature = cpuTemperature
        self.gpuTemperature = gpuTemperature
        self.fanSpeeds = fanSpeeds
        self.isOverheating = isOverheating
    }
}
