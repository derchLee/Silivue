import Foundation
import MonitorEngine

/// A local-only explanation of noteworthy system pressure during a short time window.
/// It intentionally contains no process names, network identities, or file paths.
public struct ReplayFinding: Identifiable, Equatable {
    public enum Severity: Int, Comparable {
        case info
        case warning
        case critical

        public static func < (lhs: Severity, rhs: Severity) -> Bool { lhs.rawValue < rhs.rawValue }
    }

    public let id = UUID()
    public let timestamp: Date
    public let severity: Severity
    public let title: String
    public let evidence: String
    public let nextStep: String

    public init(timestamp: Date, severity: Severity, title: String, evidence: String, nextStep: String) {
        self.timestamp = timestamp
        self.severity = severity
        self.title = title
        self.evidence = evidence
        self.nextStep = nextStep
    }
}

public struct PerformanceReplay {
    public let windowStart: Date
    public let windowEnd: Date
    public let sampleCount: Int
    public let findings: [ReplayFinding]

    public init(windowStart: Date, windowEnd: Date, sampleCount: Int, findings: [ReplayFinding]) {
        self.windowStart = windowStart
        self.windowEnd = windowEnd
        self.sampleCount = sampleCount
        self.findings = findings
    }
}

public struct PerformanceReplayAnalyzer {
    public init() {}

    public func analyze(samples: [String: [AnyMonitorSample]], from: Date, to: Date) -> PerformanceReplay {
        var findings: [ReplayFinding] = []
        findings += cpuFindings(samples["cpu", default: []])
        findings += memoryFindings(samples["memory", default: []])
        findings += memoryGrowthFindings(samples["memory", default: []])
        findings += networkFindings(samples["network", default: []])
        findings += diskFindings(samples["disk", default: []])
        findings += thermalFindings(samples["temperature", default: []])
        findings.sort {
            $0.severity == $1.severity ? $0.timestamp > $1.timestamp : $0.severity > $1.severity
        }
        return PerformanceReplay(
            windowStart: from,
            windowEnd: to,
            sampleCount: samples.values.reduce(0) { $0 + $1.count },
            findings: findings
        )
    }

    private func cpuFindings(_ samples: [AnyMonitorSample]) -> [ReplayFinding] {
        guard let peak = samples.compactMap({ sample -> (Date, Double)? in
            sample.cpu.map { (sample.timestamp, $0.usagePercent) }
        }).max(by: { $0.1 < $1.1 }), peak.1 >= 80 else { return [] }
        return [ReplayFinding(
            timestamp: peak.0,
            severity: peak.1 >= 95 ? .critical : .warning,
            title: AppLocalization.text("High CPU activity"),
            evidence: AppLocalization.format("CPU peaked at %d%% during this replay window.", Int(peak.1)),
            nextStep: AppLocalization.text("Open Activity Monitor to identify the busiest app.")
        )]
    }

    private func memoryFindings(_ samples: [AnyMonitorSample]) -> [ReplayFinding] {
        let memory = samples.compactMap(\.memory)
        guard let latest = memory.last else { return [] }
        if latest.pressureLevel == .critical || latest.pressureLevel == .warning {
            let label = latest.pressureLevel == .critical ? AppLocalization.text("Critical") : AppLocalization.text("Elevated")
            return [ReplayFinding(
                timestamp: latest.timestamp,
                severity: latest.pressureLevel == .critical ? .critical : .warning,
                title: AppLocalization.format("%@ memory pressure", label),
                evidence: AppLocalization.format("macOS reported %@ memory pressure; swap use is %@.", label.lowercased(), byteText(latest.swapUsedBytes)),
                nextStep: AppLocalization.text("Close memory-heavy apps or review them in Activity Monitor.")
            )]
        }
        guard let first = memory.first,
              latest.swapUsedBytes >= first.swapUsedBytes + 512 * 1_024 * 1_024 else { return [] }
        return [ReplayFinding(
            timestamp: latest.timestamp,
            severity: .warning,
            title: AppLocalization.text("Swap usage increased"),
            evidence: AppLocalization.format("Swap grew by %@ during this replay window.", byteText(latest.swapUsedBytes - first.swapUsedBytes)),
            nextStep: AppLocalization.text("Review memory-heavy apps if the Mac feels slow.")
        )]
    }

    private func networkFindings(_ samples: [AnyMonitorSample]) -> [ReplayFinding] {
        guard let peak = samples.compactMap({ sample -> (Date, Double)? in
            guard let network = sample.network else { return nil }
            return (sample.timestamp, max(network.uploadBytesPerSec, network.downloadBytesPerSec))
        }).max(by: { $0.1 < $1.1 }), peak.1 >= 5 * 1_024 * 1_024 else { return [] }
        return [ReplayFinding(
            timestamp: peak.0,
            severity: .info,
            title: AppLocalization.text("Network traffic spike"),
            evidence: AppLocalization.format("Transfer rate peaked at %@.", speedText(peak.1)),
            nextStep: AppLocalization.text("This can be normal during downloads, backups, or video calls.")
        )]
    }

    private func memoryGrowthFindings(_ samples: [AnyMonitorSample]) -> [ReplayFinding] {
        let memory = samples.compactMap(\.memory)
        guard memory.count >= 4,
              let first = memory.first,
              let latest = memory.last,
              latest.usedBytes >= first.usedBytes + 1 * 1_024 * 1_024 * 1_024 else { return [] }
        let increasingSteps = zip(memory, memory.dropFirst()).filter { $1.usedBytes >= $0.usedBytes }.count
        guard Double(increasingSteps) / Double(memory.count - 1) >= 0.75 else { return [] }
        return [ReplayFinding(
            timestamp: latest.timestamp,
            severity: .warning,
            title: AppLocalization.text("Memory use kept growing"),
            evidence: AppLocalization.format("Memory increased by %@ across most samples; this is a system-level trend, not a per-app diagnosis.", byteText(latest.usedBytes - first.usedBytes)),
            nextStep: AppLocalization.text("Use Activity Monitor to inspect apps with growing memory use.")
        )]
    }

    private func diskFindings(_ samples: [AnyMonitorSample]) -> [ReplayFinding] {
        guard let volume = samples.compactMap(\.disk).flatMap(\.volumes).max(by: { $0.usagePercent < $1.usagePercent }),
              100 - volume.usagePercent <= 10 else { return [] }
        return [ReplayFinding(
            timestamp: samples.last?.timestamp ?? Date(),
            severity: volume.usagePercent >= 95 ? .critical : .warning,
            title: AppLocalization.text("Low disk space"),
            evidence: AppLocalization.format("The fullest volume has only %d%% free space remaining.", Int(100 - volume.usagePercent)),
            nextStep: AppLocalization.text("Free space before installing updates or running large workloads.")
        )]
    }

    private func thermalFindings(_ samples: [AnyMonitorSample]) -> [ReplayFinding] {
        guard let worst = samples.compactMap(\.temperature).max(by: { thermalRank($0.thermalState) < thermalRank($1.thermalState) }),
              worst.thermalState == .serious || worst.thermalState == .critical else { return [] }
        return [ReplayFinding(
            timestamp: worst.timestamp,
            severity: worst.thermalState == .critical ? .critical : .warning,
            title: AppLocalization.text("Thermal pressure detected"),
            evidence: AppLocalization.format("macOS reported %@ thermal pressure.", worst.thermalState.rawValue),
            nextStep: AppLocalization.text("Reduce heavy workloads and improve airflow.")
        )]
    }

    private func byteText(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }

    private func speedText(_ bytesPerSecond: Double) -> String {
        byteText(UInt64(bytesPerSecond)) + "/s"
    }

    private func thermalRank(_ state: SystemThermalState) -> Int {
        switch state {
        case .nominal: return 0
        case .fair: return 1
        case .serious: return 2
        case .critical: return 3
        }
    }
}

public enum DiagnosticReportExporter {
    public static func makeMarkdown(_ replay: PerformanceReplay) -> String {
        let formatter = ISO8601DateFormatter()
        var lines = [
            "# " + AppLocalization.text("Silivue Performance Replay"),
            "",
            AppLocalization.format("Window: %@ to %@", formatter.string(from: replay.windowStart), formatter.string(from: replay.windowEnd)),
            AppLocalization.format("Samples analyzed: %d", replay.sampleCount),
            "",
            AppLocalization.text("This report is created locally. It contains no process names, IP addresses, Wi-Fi names, file paths, or account information."),
            "",
            "## " + AppLocalization.text("Findings")
        ]
        if replay.findings.isEmpty {
            lines.append(AppLocalization.text("No notable system-level pressure was detected in this window."))
        } else {
            for finding in replay.findings {
                lines += ["### \(finding.title)", finding.evidence, AppLocalization.format("Next step: %@", finding.nextStep), ""]
            }
        }
        return lines.joined(separator: "\n")
    }
}
