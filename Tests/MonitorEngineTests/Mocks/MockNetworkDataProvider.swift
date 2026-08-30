@testable import MonitorEngine

final class MockNetworkDataProvider: NetworkDataProvider {
    var stubbedData: NetworkInterfaceData
    private(set) var callCount = 0

    var dataSequence: [NetworkInterfaceData]?
    private var sequenceIndex = 0

    init(stubbedData: NetworkInterfaceData = NetworkInterfaceData(
        ibytes: 0, obytes: 0, ipackets: 0, opackets: 0)) {
        self.stubbedData = stubbedData
    }

    func readNetworkData() -> NetworkInterfaceData {
        callCount += 1
        if let sequence = dataSequence, sequenceIndex < sequence.count {
            let result = sequence[sequenceIndex]
            sequenceIndex += 1
            return result
        }
        return stubbedData
    }
}
