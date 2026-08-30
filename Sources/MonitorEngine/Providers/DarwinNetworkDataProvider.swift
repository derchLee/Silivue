import Foundation

/// 生产环境网络数据提供者，包装ifaddr API
public final class DarwinNetworkDataProvider: NetworkDataProvider {
    public init() {}

    public func readNetworkData() -> NetworkInterfaceData {
        var ibytes: UInt64 = 0
        var obytes: UInt64 = 0
        var ipackets: UInt64 = 0
        var opackets: UInt64 = 0

        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else {
            return NetworkInterfaceData(ibytes: 0, obytes: 0, ipackets: 0, opackets: 0)
        }
        defer { freeifaddrs(ifaddr) }

        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let name = String(cString: ptr.pointee.ifa_name)
            // 跳过loopback接口
            guard name != "lo0" else { continue }

            let addr = ptr.pointee.ifa_addr
            guard let addr = addr, addr.pointee.sa_family == AF_LINK else { continue }

            if let data = ptr.pointee.ifa_data {
                let networkData = data.assumingMemoryBound(to: if_data.self)
                ibytes += UInt64(networkData.pointee.ifi_ibytes)
                obytes += UInt64(networkData.pointee.ifi_obytes)
                ipackets += UInt64(networkData.pointee.ifi_ipackets)
                opackets += UInt64(networkData.pointee.ifi_opackets)
            }
        }

        return NetworkInterfaceData(ibytes: ibytes, obytes: obytes, ipackets: ipackets, opackets: opackets)
    }
}
