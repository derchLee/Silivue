import XCTest
import MonitorEngine
@testable import UIComponents

final class ProcessSortColumnTests: XCTestCase {
    private let processes = [
        ProcessInfoItem(pid: 1, name: "Low CPU", cpuPercent: 10, memoryBytes: 300),
        ProcessInfoItem(pid: 2, name: "High CPU", cpuPercent: 80, memoryBytes: 100),
        ProcessInfoItem(pid: 3, name: "Middle CPU", cpuPercent: 40, memoryBytes: 200)
    ]

    func testCPUDescendingIsDefaultOrder() {
        let result = ProcessSortColumn.cpu.sort(processes, ascending: false)

        XCTAssertEqual(result.map(\.pid), [2, 3, 1])
    }

    func testMemoryAscending() {
        let result = ProcessSortColumn.memory.sort(processes, ascending: true)

        XCTAssertEqual(result.map(\.pid), [2, 3, 1])
    }

    func testMemoryDescending() {
        let result = ProcessSortColumn.memory.sort(processes, ascending: false)

        XCTAssertEqual(result.map(\.pid), [1, 3, 2])
    }
}
