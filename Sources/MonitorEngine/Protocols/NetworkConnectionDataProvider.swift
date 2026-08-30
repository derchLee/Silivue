import Foundation

public struct NetworkConnectionInfo: Equatable {
    public let ssid: String?
    public let localIP: String?
    public let interfaceName: String?

    public init(ssid: String?, localIP: String?, interfaceName: String?) {
        self.ssid = ssid
        self.localIP = localIP
        self.interfaceName = interfaceName
    }
}

public protocol NetworkConnectionDataProvider {
    func readConnectionInfo() -> NetworkConnectionInfo
}
