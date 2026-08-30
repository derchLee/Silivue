import Foundation

/// 生产环境内存数据提供者，包装vm_statistics64和sysctl
public final class MachMemoryDataProvider: MemoryDataProvider {
    public init() {}

    public func readMemoryPages() -> MemoryPageData {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(
            MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size
        )

        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }

        guard result == KERN_SUCCESS else {
            return MemoryPageData(
                freePages: 0, activePages: 0, inactivePages: 0,
                wiredPages: 0, compressedPages: 0, purgeablePages: 0,
                pageSize: UInt64(vm_kernel_page_size), totalMemory: totalMemoryBytes, swapUsed: 0
            )
        }

        return MemoryPageData(
            freePages: UInt64(stats.free_count),
            activePages: UInt64(stats.active_count),
            inactivePages: UInt64(stats.inactive_count),
            wiredPages: UInt64(stats.wire_count),
            compressedPages: UInt64(stats.compressor_page_count),
            purgeablePages: UInt64(stats.purgeable_count),
            pageSize: UInt64(vm_kernel_page_size),
            totalMemory: totalMemoryBytes,
            swapUsed: swapUsedBytes
        )
    }

    private var totalMemoryBytes: UInt64 {
        var size: UInt64 = 0
        var sizeLength = MemoryLayout<UInt64>.size
        sysctlbyname("hw.memsize", &size, &sizeLength, nil, 0)
        return size
    }

    private var swapUsedBytes: UInt64 {
        // vm.swapusage 返回 xsw_usage 结构体
        var usage = xsw_usage()
        var size = MemoryLayout<xsw_usage>.size
        let result = sysctlbyname("vm.swapusage", &usage, &size, nil, 0)
        guard result == 0 else { return 0 }
        return usage.xsu_used
    }
}
