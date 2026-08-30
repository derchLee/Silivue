import Foundation
import Darwin

public struct SignalProcessKiller: ProcessKiller {
    public init() {}

    public func terminate(pid: Int32) -> Bool {
        kill(pid, SIGTERM) == 0
    }
}

public final class LibprocDataProvider: ProcessDataProvider {
    private struct CPUReading {
        let nanoseconds: UInt64
        let sampledAt: UInt64
    }

    private var previousCPU: [Int32: CPUReading] = [:]
    private let lock = NSLock()

    public init() {}

    public func readProcessList(topN: Int = 500) -> ProcessListData {
        lock.lock()
        defer { lock.unlock() }

        let requestedCount = proc_listallpids(nil, 0)
        guard requestedCount > 0 else {
            return ProcessListData(processes: [], totalProcessCount: 0)
        }

        var pids = [Int32](repeating: 0, count: Int(requestedCount) + 128)
        let actualCount = pids.withUnsafeMutableBytes { buffer in
            proc_listallpids(buffer.baseAddress, Int32(buffer.count))
        }
        guard actualCount > 0 else {
            return ProcessListData(processes: [], totalProcessCount: 0)
        }

        let now = DispatchTime.now().uptimeNanoseconds
        var currentCPU: [Int32: CPUReading] = [:]
        var processes: [ProcessInfoItem] = []

        for pid in pids.prefix(Int(actualCount)) where pid > 0 {
            var taskInfo = proc_taskinfo()
            let infoSize = MemoryLayout<proc_taskinfo>.size
            let readSize = withUnsafeMutablePointer(to: &taskInfo) { pointer in
                proc_pidinfo(pid, PROC_PIDTASKINFO, 0, pointer, Int32(infoSize))
            }
            guard readSize == infoSize else { continue }

            let cpuNanoseconds = taskInfo.pti_total_user + taskInfo.pti_total_system
            currentCPU[pid] = CPUReading(nanoseconds: cpuNanoseconds, sampledAt: now)
            let cpuPercent = calculateCPUPercent(pid: pid, nanoseconds: cpuNanoseconds, now: now)

            processes.append(ProcessInfoItem(
                pid: pid,
                name: processName(pid: pid),
                cpuPercent: cpuPercent,
                memoryBytes: taskInfo.pti_resident_size,
                path: processPath(pid: pid),
                ports: []
            ))
        }

        previousCPU = currentCPU
        let sorted = processes.sorted { lhs, rhs in
            if lhs.cpuPercent == rhs.cpuPercent { return lhs.memoryBytes > rhs.memoryBytes }
            return lhs.cpuPercent > rhs.cpuPercent
        }
        return ProcessListData(
            processes: Array(sorted.prefix(max(0, topN))),
            totalProcessCount: processes.count
        )
    }

    private func calculateCPUPercent(pid: Int32, nanoseconds: UInt64, now: UInt64) -> Double {
        guard let previous = previousCPU[pid],
              nanoseconds >= previous.nanoseconds,
              now > previous.sampledAt else { return 0 }

        let cpuDelta = Double(nanoseconds - previous.nanoseconds)
        let timeDelta = Double(now - previous.sampledAt)
        return cpuDelta / timeDelta * 100
    }

    private func processName(pid: Int32) -> String {
        var buffer = [CChar](repeating: 0, count: Int(MAXPATHLEN))
        guard proc_name(pid, &buffer, UInt32(buffer.count)) > 0 else {
            return "PID \(pid)"
        }
        return String(cString: buffer)
    }

    private func processPath(pid: Int32) -> String? {
        var buffer = [CChar](repeating: 0, count: Int(MAXPATHLEN))
        guard proc_pidpath(pid, &buffer, UInt32(buffer.count)) > 0 else { return nil }
        return String(cString: buffer)
    }
}
