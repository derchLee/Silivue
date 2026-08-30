@testable import MonitorEngine

final class MockCPUDataProvider: CPUDataProvider {
    var stubbedTickData: CPUTickData
    private(set) var callCount = 0

    var tickSequence: [CPUTickData]?
    private var sequenceIndex = 0

    init(stubbedTickData: CPUTickData = CPUTickData(user: 0, system: 0, idle: 0, nice: 0)) {
        self.stubbedTickData = stubbedTickData
    }

    func readCPUTicks() -> CPUTickData {
        callCount += 1
        if let sequence = tickSequence, sequenceIndex < sequence.count {
            let result = sequence[sequenceIndex]
            sequenceIndex += 1
            return result
        }
        return stubbedTickData
    }
}
