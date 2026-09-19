import XCTest
@testable import DataLayer
@testable import MonitorEngine

final class PerformanceReplayAnalyzerTests: XCTestCase {
    func testReportsSustainedSystemPressureWithoutSensitiveIdentifiers() {
        let now = Date()
        let memory = MemorySample(
            timestamp: now,
            usedBytes: 14 * 1_024 * 1_024 * 1_024,
            totalBytes: 16 * 1_024 * 1_024 * 1_024,
            usagePercent: 88,
            pressureLevel: .critical,
            swapUsedBytes: 2 * 1_024 * 1_024 * 1_024,
            compressedBytes: 1
        )
        let cpu = CPUSample(timestamp: now, usagePercent: 96, userPercent: 80, systemPercent: 16, idlePercent: 4, coreCount: 8)
        let replay = PerformanceReplayAnalyzer().analyze(
            samples: ["cpu": [AnyMonitorSample(cpu)], "memory": [AnyMonitorSample(memory)]],
            from: now.addingTimeInterval(-900),
            to: now
        )

        XCTAssertEqual(replay.findings.map(\.title), ["High CPU activity", "Critical memory pressure"])
        let report = DiagnosticReportExporter.makeMarkdown(replay)
        XCTAssertTrue(report.contains("no process names"))
        XCTAssertFalse(report.contains("SSID"))
    }

    func testIgnoresNormalActivity() {
        let now = Date()
        let cpu = CPUSample(timestamp: now, usagePercent: 25, userPercent: 20, systemPercent: 5, idlePercent: 75, coreCount: 8)
        let replay = PerformanceReplayAnalyzer().analyze(
            samples: ["cpu": [AnyMonitorSample(cpu)]], from: now.addingTimeInterval(-900), to: now
        )
        XCTAssertTrue(replay.findings.isEmpty)
    }

    func testReportsPersistentMemoryGrowthAsAnInvestigationSignal() {
        let start = Date()
        let total = UInt64(16 * 1_024 * 1_024 * 1_024)
        let samples = (0..<6).map { index in
            let gibibyte = UInt64(1_024 * 1_024 * 1_024)
            let used = UInt64(7 + index) * gibibyte
            return AnyMonitorSample(MemorySample(
                timestamp: start.addingTimeInterval(Double(index * 120)),
                usedBytes: used,
                totalBytes: total,
                usagePercent: Double(44 + index * 6),
                pressureLevel: .normal,
                swapUsedBytes: 0,
                compressedBytes: 0
            ))
        }

        let replay = PerformanceReplayAnalyzer().analyze(
            samples: ["memory": samples], from: start, to: start.addingTimeInterval(600)
        )

        XCTAssertTrue(replay.findings.contains { $0.title == "Memory use kept growing" })
        XCTAssertTrue(replay.findings.contains { $0.evidence.contains("not a per-app diagnosis") })
    }
}
