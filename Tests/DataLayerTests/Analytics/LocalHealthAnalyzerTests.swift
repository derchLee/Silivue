import XCTest
import MonitorEngine
@testable import DataLayer

final class LocalHealthAnalyzerTests: XCTestCase {
    func testNormalSamplesProduceHealthyReport() {
        let now = Date()
        let current = [
            "cpu": [AnyMonitorSample(cpu(at: now, usage: 20))],
            "memory": [AnyMonitorSample(memory(at: now, usage: 55, pressure: .normal))]
        ]

        let report = LocalHealthAnalyzer().analyze(current: current, previous: [:])

        XCTAssertEqual(report.score, 100)
        XCTAssertTrue(report.events.isEmpty)
        XCTAssertEqual(report.comparisons.count, 2)
    }

    func testSustainedHighCPUProducesActionableEvent() {
        let start = Date(timeIntervalSince1970: 1_000)
        let samples = stride(from: 0, through: 150, by: 30).map {
            AnyMonitorSample(cpu(at: start.addingTimeInterval(Double($0)), usage: 92))
        }

        let report = LocalHealthAnalyzer().analyze(current: ["cpu": samples], previous: [:])

        XCTAssertEqual(report.events.first?.metric, .cpu)
        XCTAssertEqual(report.events.first?.severity, .warning)
        XCTAssertLessThan(report.score, 100)
    }

    func testCriticalMemoryPressureAndLowDiskReduceScore() {
        let now = Date()
        let disk = DiskSample(timestamp: now, volumes: [
            DiskVolumeInfo(name: "Macintosh HD", mountPoint: "/", usedBytes: 950, totalBytes: 1_000, usagePercent: 95)
        ])
        let current = [
            "memory": [AnyMonitorSample(memory(at: now, usage: 94, pressure: .critical))],
            "disk": [AnyMonitorSample(disk)]
        ]

        let report = LocalHealthAnalyzer().analyze(current: current, previous: [:])

        XCTAssertEqual(report.events.filter { $0.severity == .critical }.count, 2)
        XCTAssertEqual(report.score, 64)
    }

    func testComparisonCalculatesChangeAgainstPreviousPeriod() {
        let now = Date()
        let current = ["cpu": [AnyMonitorSample(cpu(at: now, usage: 60))]]
        let previous = ["cpu": [AnyMonitorSample(cpu(at: now.addingTimeInterval(-100), usage: 40))]]

        let report = LocalHealthAnalyzer().analyze(current: current, previous: previous)

        XCTAssertEqual(report.comparisons.first?.changePercent ?? 0, 50, accuracy: 0.001)
    }

    func testCSVExporterIncludesMetricRowsWithoutRawObjectDescriptions() {
        let now = Date(timeIntervalSince1970: 1_000)
        let csv = HistoryCSVExporter.makeCSV(samplesByMonitor: ["cpu": [AnyMonitorSample(cpu(at: now, usage: 42))]])

        XCTAssertTrue(csv.contains("timestamp,metric,value,unit,details"))
        XCTAssertTrue(csv.contains("\"CPU\",\"42.00\",\"%\""))
    }

    private func cpu(at date: Date, usage: Double) -> CPUSample {
        CPUSample(timestamp: date, usagePercent: usage, userPercent: usage / 2,
                  systemPercent: usage / 2, idlePercent: 100 - usage, coreCount: 8)
    }

    private func memory(at date: Date, usage: Double, pressure: MemoryPressureLevel) -> MemorySample {
        MemorySample(timestamp: date, usedBytes: 8, totalBytes: 16, usagePercent: usage,
                     pressureLevel: pressure, swapUsedBytes: 0, compressedBytes: 0)
    }
}
