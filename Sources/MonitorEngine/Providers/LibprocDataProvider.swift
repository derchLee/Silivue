import Foundation
import Darwin

public struct SignalProcessKiller: ProcessKiller {
    public init() {}

    public func terminate(pid: Int32) -> Bool {
        kill(pid, SIGTERM) == 0
    }
}

// MARK: - Port Cache (10秒TTL)

private final class PortCache {
    static let shared = PortCache()
    private var cache: [Int32: [String]] = [:]
    private var lastFetch: Date = .distantPast
    private let ttl: TimeInterval = 10

    func ports(for pid: Int32) -> [String] {
        if Date().timeIntervalSince(lastFetch) > ttl {
            refresh()
        }
        return cache[pid] ?? []
    }

    private func refresh() {
        let task = Process()
        task.launchPath = "/usr/sbin/lsof"
        task.arguments = ["-iTCP", "-sTCP:LISTEN", "-n", "-P"]
        task.environment = ["LANG": "en_US.UTF-8"]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = FileHandle.nullDevice

        var outputData = Data()
        pipe.fileHandleForReading.readabilityHandler = { handler in
            outputData.append(handler.availableData)
        }

        do {
            try task.run()
            task.waitUntilExit()
        } catch {
            pipe.fileHandleForReading.readabilityHandler = nil
            cache = [:]
            lastFetch = Date()
            return
        }

        pipe.fileHandleForReading.readabilityHandler = nil
        outputData.append(pipe.fileHandleForReading.readDataToEndOfFile())

        guard task.terminationStatus == 0 else {
            cache = [:]
            lastFetch = Date()
            return
        }

        guard let output = String(data: outputData, encoding: .utf8) else {
            cache = [:]
            lastFetch = Date()
            return
        }

        var newCache: [Int32: [String]] = [:]
        for line in output.components(separatedBy: "\n") {
            let parts = line.split(separator: " ", omittingEmptySubsequences: true)
            guard parts.count >= 9 else { continue }

            guard let pid = Int32(parts[1]) else { continue }
            // 格式: NAME -> IP:PORT or *:PORT or 0.0.0.0:PORT
            let namePart = String(parts[8])
            let port: String
            if let colonIdx = namePart.lastIndex(of: ":") {
                port = String(namePart[namePart.index(after: colonIdx)...])
            } else {
                port = namePart
            }

            newCache[pid, default: []].append(port)
        }

        cache = newCache
        lastFetch = Date()
    }
}

// MARK: - Data Provider

public final class LibprocDataProvider: ProcessDataProvider {
    public init() {}

    public func readProcessList(topN: Int = 500) -> ProcessListData {
        let task = Process()
        task.launchPath = "/bin/ps"
        task.arguments = ["-arcwwwxo", "%cpu %mem pid command"]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = FileHandle.nullDevice

        var outputData = Data()
        pipe.fileHandleForReading.readabilityHandler = { handler in
            outputData.append(handler.availableData)
        }

        do {
            try task.run()
            task.waitUntilExit()
        } catch {
            pipe.fileHandleForReading.readabilityHandler = nil
            return ProcessListData(processes: [], totalProcessCount: 0)
        }

        pipe.fileHandleForReading.readabilityHandler = nil
        outputData.append(pipe.fileHandleForReading.readDataToEndOfFile())

        guard task.terminationStatus == 0 else {
            return ProcessListData(processes: [], totalProcessCount: 0)
        }

        guard let output = String(data: outputData, encoding: .utf8) else {
            return ProcessListData(processes: [], totalProcessCount: 0)
        }

        let portCache = PortCache.shared
        var processes: [ProcessInfoItem] = []
        let lines = output.components(separatedBy: "\n").dropFirst()

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }

            let parts = trimmed.split(separator: " ", omittingEmptySubsequences: true)
            guard parts.count >= 4 else { continue }

            guard let cpuPercent = Double(parts[0]),
                  let memPercent = Double(parts[1]),
                  let pid = Int32(parts[2]) else { continue }

            let name = parts[3...].joined(separator: " ")
            let totalMemory = ProcessInfo.processInfo.physicalMemory
            let memoryBytes = UInt64(Double(totalMemory) * memPercent / 100.0)

            // Get executable path via proc_pidpath
            let path = getProcessPath(pid: pid)

            // Get listening ports
            let ports = portCache.ports(for: pid)

            processes.append(ProcessInfoItem(
                pid: pid,
                name: name,
                cpuPercent: cpuPercent,
                memoryBytes: memoryBytes,
                path: path,
                ports: ports
            ))
        }

        let sorted = processes.sorted { $0.cpuPercent > $1.cpuPercent }
        let top = Array(sorted.prefix(topN))

        return ProcessListData(processes: top, totalProcessCount: processes.count)
    }

    private func getProcessPath(pid: Int32) -> String? {
        var pathBuffer = [CChar](repeating: 0, count: Int(MAXPATHLEN))
        let result = proc_pidpath(pid, &pathBuffer, UInt32(MAXPATHLEN))
        guard result > 0 else { return nil }
        return String(cString: pathBuffer)
    }
}
