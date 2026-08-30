public struct NetworkInterfaceData: Equatable {
    public let ibytes: UInt64
    public let obytes: UInt64
    public let ipackets: UInt64
    public let opackets: UInt64

    public init(ibytes: UInt64, obytes: UInt64, ipackets: UInt64, opackets: UInt64) {
        self.ibytes = ibytes
        self.obytes = obytes
        self.ipackets = ipackets
        self.opackets = opackets
    }
}

public protocol NetworkDataProvider {
    func readNetworkData() -> NetworkInterfaceData
}
