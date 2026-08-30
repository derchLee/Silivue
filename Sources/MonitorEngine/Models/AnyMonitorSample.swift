import Foundation

/// 类型擦除包装器，让SystemMonitor协议可以统一发布不同类型的Sample
public struct AnyMonitorSample {
    public let timestamp: Date
    public let monitorID: String

    public var cpu: CPUSample? { underlying as? CPUSample }
    public var memory: MemorySample? { underlying as? MemorySample }
    public var network: NetworkSample? { underlying as? NetworkSample }
    public var disk: DiskSample? { underlying as? DiskSample }
    public var battery: BatterySample? { underlying as? BatterySample }
    public var temperature: TemperatureSample? { underlying as? TemperatureSample }
    public var process: ProcessSample? { underlying as? ProcessSample }

    private let underlying: Any

    public init<T>(_ sample: T) {
        self.underlying = sample
        if let s = sample as? CPUSample {
            self.timestamp = s.timestamp
            self.monitorID = s.monitorID
        } else if let s = sample as? MemorySample {
            self.timestamp = s.timestamp
            self.monitorID = s.monitorID
        } else if let s = sample as? NetworkSample {
            self.timestamp = s.timestamp
            self.monitorID = s.monitorID
        } else if let s = sample as? DiskSample {
            self.timestamp = s.timestamp
            self.monitorID = s.monitorID
        } else if let s = sample as? BatterySample {
            self.timestamp = s.timestamp
            self.monitorID = s.monitorID
        } else if let s = sample as? TemperatureSample {
            self.timestamp = s.timestamp
            self.monitorID = s.monitorID
        } else if let s = sample as? ProcessSample {
            self.timestamp = s.timestamp
            self.monitorID = s.monitorID
        } else {
            self.timestamp = Date()
            self.monitorID = "unknown"
        }
    }
}
