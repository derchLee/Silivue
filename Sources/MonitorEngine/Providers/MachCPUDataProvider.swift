import Foundation

/// 生产环境CPU数据提供者，包装host_statistics C API
public final class MachCPUDataProvider: CPUDataProvider {
    public init() {}

    public func readCPUTicks() -> CPUTickData {
        var info = host_cpu_load_info()
        var count = mach_msg_type_number_t(
            MemoryLayout<host_cpu_load_info>.size / MemoryLayout<integer_t>.size
        )

        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
            }
        }

        guard result == KERN_SUCCESS else {
            return CPUTickData(user: 0, system: 0, idle: 0, nice: 0)
        }

        return CPUTickData(
            user: info.cpu_ticks.0,
            system: info.cpu_ticks.1,
            idle: info.cpu_ticks.2,
            nice: info.cpu_ticks.3
        )
    }
}
