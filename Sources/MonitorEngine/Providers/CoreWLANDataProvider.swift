import Foundation
import CoreWLAN

public final class CoreWLANDataProvider: NetworkConnectionDataProvider {
    public init() {}

    /// Cached SSID, updated on main thread to avoid CWWiFiClient XPC deadlock
    private var cachedSSID: String?
    private var ssidUpdateTime: Date = .distantPast
    private let ssidCacheTTL: TimeInterval = 5

    public func readConnectionInfo() -> NetworkConnectionInfo {
        let now = Date()
        if now.timeIntervalSince(ssidUpdateTime) > ssidCacheTTL {
            if Thread.isMainThread {
                cachedSSID = CWWiFiClient.shared().interface()?.ssid()
                ssidUpdateTime = now
            } else {
                DispatchQueue.main.sync {
                    self.cachedSSID = CWWiFiClient.shared().interface()?.ssid()
                    self.ssidUpdateTime = now
                }
            }
        }

        let (localIP, interfaceName) = readLocalIP()

        return NetworkConnectionInfo(ssid: cachedSSID, localIP: localIP, interfaceName: interfaceName)
    }

    private func readLocalIP() -> (ip: String?, interface: String?) {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else {
            return (nil, nil)
        }
        defer { freeifaddrs(ifaddr) }

        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let addr = ptr.pointee.ifa_addr
            guard let addr = addr, addr.pointee.sa_family == AF_INET else { continue }
            let name = String(cString: ptr.pointee.ifa_name)
            guard name.hasPrefix("en") else { continue }

            var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            getnameinfo(addr, socklen_t(addr.pointee.sa_len), &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST)
            let ip = String(cString: hostname)
            return (ip, name)
        }

        return (nil, nil)
    }
}
