import Foundation
import MonitorEngine

public enum HealthPeriod: String, CaseIterable, Identifiable {
    case day
    case week

    public var id: String { rawValue }
    public var title: String { self == .day ? "24 Hours" : "7 Days" }
    public var comparisonTitle: String { self == .day ? "vs previous 24h" : "vs previous 7d" }
    public var duration: TimeInterval { self == .day ? 86_400 : 604_800 }
}

public enum HealthSeverity: Int, Comparable {
    case info = 0
    case warning = 1
    case critical = 2

    public static func < (lhs: HealthSeverity, rhs: HealthSeverity) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

public enum HealthMetric: String, CaseIterable {
    case cpu = "CPU"
    case memory = "Memory"
    case network = "Network"
    case disk = "Disk"
    case battery = "Battery"
    case thermal = "Thermal"
}

public struct HealthEvent: Identifiable {
    public let id = UUID()
    public let timestamp: Date
    public let metric: HealthMetric
    public let severity: HealthSeverity
    public let title: String
    public let detail: String
    public let recommendation: String

    public init(timestamp: Date, metric: HealthMetric, severity: HealthSeverity,
                title: String, detail: String, recommendation: String) {
        self.timestamp = timestamp
        self.metric = metric
        self.severity = severity
        self.title = title
        self.detail = detail
        self.recommendation = recommendation
    }
}

public struct MetricComparison: Identifiable {
    public var id: HealthMetric { metric }
    public let metric: HealthMetric
    public let average: Double
    public let peak: Double
    public let previousAverage: Double?
    public let unit: String

    public var changePercent: Double? {
        guard let previousAverage, previousAverage > 0 else { return nil }
        return (average - previousAverage) / previousAverage * 100
    }

    public init(metric: HealthMetric, average: Double, peak: Double,
                previousAverage: Double?, unit: String) {
        self.metric = metric
        self.average = average
        self.peak = peak
        self.previousAverage = previousAverage
        self.unit = unit
    }
}

public struct HealthReport {
    public let score: Int
    public let summary: String
    public let events: [HealthEvent]
    public let comparisons: [MetricComparison]
    public let sampleCount: Int

    public init(score: Int, summary: String, events: [HealthEvent],
                comparisons: [MetricComparison], sampleCount: Int) {
        self.score = score
        self.summary = summary
        self.events = events
        self.comparisons = comparisons
        self.sampleCount = sampleCount
    }
}

public struct LocalHealthAnalyzer {
    public init() {}

    public func analyze(current: [String: [AnyMonitorSample]],
                        previous: [String: [AnyMonitorSample]]) -> HealthReport {
        var events: [HealthEvent] = []
        events.append(contentsOf: cpuEvents(current["cpu"] ?? []))
        events.append(contentsOf: memoryEvents(current["memory"] ?? []))
        events.append(contentsOf: networkEvents(current["network"] ?? []))
        events.append(contentsOf: diskEvents(current["disk"] ?? []))
        events.append(contentsOf: batteryEvents(current["battery"] ?? [], previous: previous["battery"] ?? []))
        events.append(contentsOf: thermalEvents(current["temperature"] ?? []))
        events.sort { $0.timestamp > $1.timestamp }

        let comparisons = makeComparisons(current: current, previous: previous)
        let criticalCount = events.filter { $0.severity == .critical }.count
        let warningCount = events.filter { $0.severity == .warning }.count
        let score = max(0, 100 - min(60, criticalCount * 18) - min(30, warningCount * 7))
        let summary: String
        if criticalCount > 0 {
            summary = "Immediate attention recommended"
        } else if warningCount > 0 {
            summary = "A few items may need attention"
        } else if comparisons.isEmpty {
            summary = "Collecting enough data for a health summary"
        } else {
            summary = "System metrics stayed within normal ranges"
        }
        return HealthReport(
            score: score,
            summary: summary,
            events: events,
            comparisons: comparisons,
            sampleCount: current.values.reduce(0) { $0 + $1.count }
        )
    }

    private func cpuEvents(_ samples: [AnyMonitorSample]) -> [HealthEvent] {
        let values = samples.compactMap { sample -> (Date, Double)? in
            guard let value = sample.cpu?.usagePercent else { return nil }
            return (sample.timestamp, value)
        }
        guard let peak = values.max(by: { $0.1 < $1.1 }) else { return [] }
        let sustained = longestDurationAbove(values, threshold: 80)
        if sustained >= 120 {
            return [HealthEvent(timestamp: peak.0, metric: .cpu,
                                severity: peak.1 >= 95 ? .critical : .warning,
                                title: "Sustained high CPU",
                                detail: "CPU stayed above 80% for " + durationText(sustained) + "; peak " + String(Int(peak.1)) + "%.",
                                recommendation: "Open Activity Monitor to identify the busiest app.")]
        }
        return []
    }

    private func memoryEvents(_ samples: [AnyMonitorSample]) -> [HealthEvent] {
        let memory = samples.compactMap(\.memory)
        guard let worst = memory.max(by: { severity(of: $0.pressureLevel) < severity(of: $1.pressureLevel) }) else { return [] }
        if worst.pressureLevel == .critical {
            return [HealthEvent(timestamp: worst.timestamp, metric: .memory, severity: .critical,
                                title: "Critical memory pressure",
                                detail: "macOS reported critical memory pressure; swap reached " + byteText(worst.swapUsedBytes) + ".",
                                recommendation: "Close memory-heavy apps or restart apps with growing usage.")]
        }
        if worst.pressureLevel == .warning || memory.contains(where: { $0.usagePercent >= 90 }) {
            return [HealthEvent(timestamp: worst.timestamp, metric: .memory, severity: .warning,
                                title: "Elevated memory pressure",
                                detail: "Memory usage reached " + String(Int(memory.map(\.usagePercent).max() ?? 0)) + "%.",
                                recommendation: "Review memory use in Activity Monitor if the system feels slow.")]
        }
        return []
    }

    private func networkEvents(_ samples: [AnyMonitorSample]) -> [HealthEvent] {
        let values = samples.compactMap { sample -> (Date, Double)? in
            guard let net = sample.network else { return nil }
            return (sample.timestamp, net.uploadBytesPerSec + net.downloadBytesPerSec)
        }
        guard values.count >= 10 else { return [] }
        let sorted = values.map(\.1).sorted()
        let median = sorted[sorted.count / 2]
        guard let peak = values.max(by: { $0.1 < $1.1 }), peak.1 >= 1_048_576,
              peak.1 >= max(median * 5, 1_048_576) else { return [] }
        return [HealthEvent(timestamp: peak.0, metric: .network, severity: .info,
                            title: "Network traffic spike",
                            detail: "Combined transfer rate peaked at " + speedText(peak.1) + ".",
                            recommendation: "This can be normal during downloads, backups, or video calls.")]
    }

    private func diskEvents(_ samples: [AnyMonitorSample]) -> [HealthEvent] {
        let volumes = samples.compactMap(\.disk).flatMap(\.volumes)
        guard let fullest = volumes.max(by: { $0.usagePercent < $1.usagePercent }), fullest.usagePercent >= 80 else { return [] }
        return [HealthEvent(timestamp: samples.last?.timestamp ?? Date(), metric: .disk,
                            severity: fullest.usagePercent >= 90 ? .critical : .warning,
                            title: "Low disk space",
                            detail: (fullest.name.isEmpty ? fullest.mountPoint : fullest.name) + " is " + String(Int(fullest.usagePercent)) + "% full.",
                            recommendation: "Keep at least 10–20% free for updates, swap, and temporary files.")]
    }

    private func batteryEvents(_ samples: [AnyMonitorSample], previous: [AnyMonitorSample]) -> [HealthEvent] {
        guard let latest = samples.compactMap(\.battery).last, latest.healthPercent > 0 else { return [] }
        let previousHealth = previous.compactMap(\.battery).last?.healthPercent
        if latest.healthPercent < 80 {
            return [HealthEvent(timestamp: latest.timestamp, metric: .battery, severity: .warning,
                                title: "Battery health reduced",
                                detail: "Maximum capacity is " + String(Int(latest.healthPercent)) + "% after " + String(latest.cycleCount) + " cycles.",
                                recommendation: "Consider battery service if runtime no longer meets your needs.")]
        }
        if let previousHealth, previousHealth - latest.healthPercent >= 2 {
            return [HealthEvent(timestamp: latest.timestamp, metric: .battery, severity: .info,
                                title: "Battery health changed",
                                detail: "Maximum capacity decreased by " + String(Int(previousHealth - latest.healthPercent)) + " points.",
                                recommendation: "Watch the trend over several weeks before taking action.")]
        }
        return []
    }

    private func thermalEvents(_ samples: [AnyMonitorSample]) -> [HealthEvent] {
        let thermal = samples.compactMap(\.temperature)
        guard let worst = thermal.max(by: { thermalRank($0.thermalState) < thermalRank($1.thermalState) }),
              thermalRank(worst.thermalState) >= 2 else { return [] }
        return [HealthEvent(timestamp: worst.timestamp, metric: .thermal,
                            severity: worst.thermalState == .critical ? .critical : .warning,
                            title: "Thermal pressure detected",
                            detail: "macOS reported " + worst.thermalState.rawValue + " thermal pressure.",
                            recommendation: "Reduce heavy workloads and improve airflow until the Mac cools down.")]
    }

    private func makeComparisons(current: [String: [AnyMonitorSample]], previous: [String: [AnyMonitorSample]]) -> [MetricComparison] {
        let definitions: [(HealthMetric, String, (AnyMonitorSample) -> Double?)] = [
            (.cpu, "%", { $0.cpu?.usagePercent }),
            (.memory, "%", { $0.memory?.usagePercent }),
            (.network, "B/s", { sample in sample.network.map { $0.uploadBytesPerSec + $0.downloadBytesPerSec } }),
            (.disk, "%", { $0.disk?.volumes.map(\.usagePercent).max() }),
            (.battery, "%", { $0.battery?.healthPercent })
        ]
        return definitions.compactMap { metric, unit, extractor in
            let currentValues = current[monitorID(for: metric), default: []].compactMap(extractor)
            guard !currentValues.isEmpty else { return nil }
            let previousValues = previous[monitorID(for: metric), default: []].compactMap(extractor)
            return MetricComparison(metric: metric,
                                    average: average(currentValues),
                                    peak: currentValues.max() ?? 0,
                                    previousAverage: previousValues.isEmpty ? nil : average(previousValues),
                                    unit: unit)
        }
    }

    private func longestDurationAbove(_ values: [(Date, Double)], threshold: Double) -> TimeInterval {
        guard !values.isEmpty else { return 0 }
        let ordered = values.sorted { $0.0 < $1.0 }
        var longest: TimeInterval = 0
        var start: Date?
        var previous: Date?
        for value in ordered {
            if value.1 >= threshold {
                if start == nil || (previous.map { value.0.timeIntervalSince($0) > 60 } ?? false) {
                    start = value.0
                }
                previous = value.0
                if let start { longest = max(longest, value.0.timeIntervalSince(start)) }
            } else {
                start = nil
                previous = nil
            }
        }
        return longest
    }

    private func severity(of level: MemoryPressureLevel) -> Int { level.rawValue }
    private func thermalRank(_ state: SystemThermalState) -> Int {
        switch state { case .nominal: return 0; case .fair: return 1; case .serious: return 2; case .critical: return 3 }
    }
    private func average(_ values: [Double]) -> Double { values.reduce(0, +) / Double(values.count) }
    private func monitorID(for metric: HealthMetric) -> String { metric == .thermal ? "temperature" : metric.rawValue.lowercased() }
    private func durationText(_ seconds: TimeInterval) -> String { seconds >= 3600 ? String(format: "%.1f h", seconds / 3600) : String(max(2, Int(seconds / 60))) + " min" }
    private func byteText(_ bytes: UInt64) -> String { String(format: "%.1f GB", Double(bytes) / 1_073_741_824) }
    private func speedText(_ bytes: Double) -> String { bytes >= 1_048_576 ? String(format: "%.1f MB/s", bytes / 1_048_576) : String(format: "%.0f KB/s", bytes / 1024) }
}
