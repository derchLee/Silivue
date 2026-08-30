public struct CPUTickData: Equatable {
    public let user: UInt32
    public let system: UInt32
    public let idle: UInt32
    public let nice: UInt32
    public let frequencyGHz: Double?
    public let performanceCoreCount: Int?
    public let efficiencyCoreCount: Int?

    public init(user: UInt32, system: UInt32, idle: UInt32, nice: UInt32,
                frequencyGHz: Double? = nil,
                performanceCoreCount: Int? = nil,
                efficiencyCoreCount: Int? = nil) {
        self.user = user
        self.system = system
        self.idle = idle
        self.nice = nice
        self.frequencyGHz = frequencyGHz
        self.performanceCoreCount = performanceCoreCount
        self.efficiencyCoreCount = efficiencyCoreCount
    }
}

public protocol CPUDataProvider {
    func readCPUTicks() -> CPUTickData
}
