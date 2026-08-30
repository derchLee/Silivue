import Foundation

public struct ProcessInfoItem: Equatable, Codable, Identifiable {
    public let pid: Int32
    public let name: String
    public let cpuPercent: Double
    public let memoryBytes: UInt64
    public let path: String?
    public let ports: [String]
    public var id: Int32 { pid }

    public init(pid: Int32, name: String, cpuPercent: Double, memoryBytes: UInt64, path: String? = nil, ports: [String] = []) {
        self.pid = pid
        self.name = name
        self.cpuPercent = cpuPercent
        self.memoryBytes = memoryBytes
        self.path = path
        self.ports = ports
    }
}

public struct ProcessListData: Equatable {
    public let processes: [ProcessInfoItem]
    public let totalProcessCount: Int

    public init(processes: [ProcessInfoItem], totalProcessCount: Int) {
        self.processes = processes
        self.totalProcessCount = totalProcessCount
    }
}

public protocol ProcessDataProvider {
    func readProcessList(topN: Int) -> ProcessListData
}

public protocol ProcessKiller {
    func terminate(pid: Int32) -> Bool
}
