@testable import MonitorEngine

final class MockNetworkConnectionDataProvider: NetworkConnectionDataProvider {
    var stubbedInfo: NetworkConnectionInfo
    private(set) var callCount = 0

    init(stubbedInfo: NetworkConnectionInfo = NetworkConnectionInfo(ssid: "TestWiFi", localIP: "192.168.1.5", interfaceName: "en0")) {
        self.stubbedInfo = stubbedInfo
    }

    func readConnectionInfo() -> NetworkConnectionInfo {
        callCount += 1
        return stubbedInfo
    }
}
