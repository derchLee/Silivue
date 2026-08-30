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

        let (frequencyGHz, perfCores, effCores) = readCPUFrequencyAndCores()

        guard result == KERN_SUCCESS else {
            return CPUTickData(user: 0, system: 0, idle: 0, nice: 0,
                               frequencyGHz: frequencyGHz,
                               performanceCoreCount: perfCores,
                               efficiencyCoreCount: effCores)
        }

        return CPUTickData(
            user: info.cpu_ticks.0,
            system: info.cpu_ticks.1,
            idle: info.cpu_ticks.2,
            nice: info.cpu_ticks.3,
            frequencyGHz: frequencyGHz,
            performanceCoreCount: perfCores,
            efficiencyCoreCount: effCores
        )
    }

    private func readCPUFrequencyAndCores() -> (frequencyGHz: Double?, perfCores: Int?, effCores: Int?) {
        // Intel Mac: hw.cpufrequency (Hz)
        var size = 0
        sysctlbyname("hw.cpufrequency", nil, &size, nil, 0)
        var freq: UInt64 = 0
        if sysctlbyname("hw.cpufrequency", &freq, &size, nil, 0) == 0, freq > 0 {
            return (Double(freq) / 1_000_000_000.0, nil, nil)
        }

        // Apple Silicon: read P-core and E-core counts via perflevel
        var perfSize = 0
        sysctlbyname("hw.perflevel0.logicalcpu", nil, &perfSize, nil, 0)
        var perfCores: Int32 = 0
        let perfOk = sysctlbyname("hw.perflevel0.logicalcpu", &perfCores, &perfSize, nil, 0) == 0

        var effSize = 0
        sysctlbyname("hw.perflevel1.logicalcpu", nil, &effSize, nil, 0)
        var effCores: Int32 = 0
        let effOk = sysctlbyname("hw.perflevel1.logicalcpu", &effCores, &effSize, nil, 0) == 0

        if perfOk && effOk {
            return (nil, Int(perfCores), Int(effCores))
        }

        return (nil, nil, nil)
    }
}
