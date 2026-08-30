@testable import MonitorEngine

final class MockProcessDataProvider: ProcessDataProvider {
    var stubbedData: ProcessListData
    private(set) var callCount = 0

    init(stubbedData: ProcessListData = ProcessListData(
        processes: [
            ProcessInfoItem(pid: 1, name: "kernel_task", cpuPercent: 5.2, memoryBytes: 2_000_000_000),
            ProcessInfoItem(pid: 42, name: "Silivue", cpuPercent: 2.1, memoryBytes: 50_000_000),
        ],
        totalProcessCount: 300)) {
        self.stubbedData = stubbedData
    }

    func readProcessList(topN: Int) -> ProcessListData {
        callCount += 1
        return stubbedData
    }
}
