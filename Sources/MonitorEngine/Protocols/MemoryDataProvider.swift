public struct MemoryPageData: Equatable {
    public let freePages: UInt64
    public let activePages: UInt64
    public let inactivePages: UInt64
    public let wiredPages: UInt64
    public let compressedPages: UInt64
    public let purgeablePages: UInt64
    public let pageSize: UInt64
    public let totalMemory: UInt64
    public let swapUsed: UInt64

    public init(freePages: UInt64, activePages: UInt64, inactivePages: UInt64,
                wiredPages: UInt64, compressedPages: UInt64, purgeablePages: UInt64,
                pageSize: UInt64, totalMemory: UInt64, swapUsed: UInt64) {
        self.freePages = freePages
        self.activePages = activePages
        self.inactivePages = inactivePages
        self.wiredPages = wiredPages
        self.compressedPages = compressedPages
        self.purgeablePages = purgeablePages
        self.pageSize = pageSize
        self.totalMemory = totalMemory
        self.swapUsed = swapUsed
    }
}

public protocol MemoryDataProvider {
    func readMemoryPages() -> MemoryPageData
}
