import AppKit
import SwiftUI
import UniformTypeIdentifiers
import MonitorEngine
import DataLayer

struct HealthDashboardView: View {
    @ObservedObject var engine: MonitorEngine
    let historyStore: HistoryStore?

    @State private var period: HealthPeriod = .day
    @State private var report: HealthReport?
    @State private var currentSamples: [String: [AnyMonitorSample]] = [:]
    @State private var isLoading = true
    @State private var exportMessage: String?

    private let monitorIDs = ["cpu", "memory", "network", "disk", "battery", "temperature"]

    var body: some View {
        DetailsScrollView {
            VStack(spacing: 10) {
                controls
                if isLoading {
                    ProgressView("Analyzing local history…")
                        .tint(TechColors.accentCyan)
                        .foregroundColor(TechColors.textSecondary)
                        .frame(maxWidth: .infinity, minHeight: 160)
                } else if let report {
                    summary(report)
                    comparisons(report.comparisons)
                    timeline(report.events)
                } else {
                    emptyHealthState
                }
                privacyNote
            }
            .padding(12)
        }
        .background(TechColors.bgPrimary)
        .task(id: period) { await loadReport() }
    }

    private var controls: some View {
        HStack(spacing: 8) {
            Picker("Summary period", selection: $period) {
                ForEach(HealthPeriod.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(width: 190)

            Text("Local health summary")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(TechColors.textMuted)
            Spacer()

            Button(action: exportCSV) {
                Label("Export CSV", systemImage: "square.and.arrow.up")
                    .font(.system(size: 10, weight: .semibold))
            }
            .buttonStyle(.bordered)
            .disabled(currentSamples.isEmpty)
            .help("Export the selected period's locally stored metric history")
        }
    }

    private func summary(_ report: HealthReport) -> some View {
        HStack(spacing: 10) {
            ZStack {
                Circle().stroke(TechColors.borderSubtle, lineWidth: 7)
                Circle()
                    .trim(from: 0, to: Double(report.score) / 100)
                    .stroke(scoreColor(report.score), style: StrokeStyle(lineWidth: 7, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 0) {
                    Text("\(report.score)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(scoreColor(report.score))
                    Text("HEALTH")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundColor(TechColors.textMuted)
                }
            }
            .frame(width: 82, height: 82)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Health score " + String(report.score) + " out of 100")

            VStack(alignment: .leading, spacing: 7) {
                Text(report.summary)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(TechColors.textPrimary)
                Text(report.events.isEmpty
                     ? "No actionable anomalies were found in the selected period."
                     : "\(report.events.filter { $0.severity != .info }.count) actionable item(s) found from \(report.sampleCount) local samples.")
                    .font(.system(size: 10))
                    .foregroundColor(TechColors.textSecondary)
                Text("Score reflects detected resource pressure and is informational, not a hardware diagnostic.")
                    .font(.system(size: 9))
                    .foregroundColor(TechColors.textMuted)
            }
            Spacer()
        }
        .padding(12)
        .background(TechColors.bgCard)
        .cornerRadius(9)
        .overlay(RoundedRectangle(cornerRadius: 9).stroke(scoreColor(report.score).opacity(0.35)))
    }

    private func comparisons(_ items: [MetricComparison]) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("PERIOD COMPARISON")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(TechColors.textMuted)
            if items.isEmpty {
                Text("More history is needed before comparisons are available.")
                    .font(.system(size: 10))
                    .foregroundColor(TechColors.textSecondary)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 7)], spacing: 7) {
                    ForEach(items) { item in comparisonCard(item) }
                }
            }
        }
    }

    private func comparisonCard(_ item: MetricComparison) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(item.metric.rawValue)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(TechColors.textSecondary)
                Spacer()
                if let change = item.changePercent {
                    Label(String(format: "%+.0f%%", change), systemImage: change > 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(changeColor(item.metric, change))
                } else {
                    Text("baseline")
                        .font(.system(size: 8))
                        .foregroundColor(TechColors.textMuted)
                }
            }
            Text(metricValue(item.average, item.unit))
                .font(.system(size: 15, weight: .bold, design: .monospaced))
                .foregroundColor(metricColor(item.metric))
            Text("avg · peak \(metricValue(item.peak, item.unit))")
                .font(.system(size: 8))
                .foregroundColor(TechColors.textMuted)
        }
        .padding(9)
        .background(TechColors.bgCard)
        .cornerRadius(7)
        .overlay(RoundedRectangle(cornerRadius: 7).stroke(TechColors.borderSubtle))
    }

    private func timeline(_ events: [HealthEvent]) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text("ANOMALY TIMELINE")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(TechColors.textMuted)
                Spacer()
                Text(period.title)
                    .font(.system(size: 8))
                    .foregroundColor(TechColors.textMuted)
            }
            if events.isEmpty {
                HStack(spacing: 7) {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(TechColors.accentGreen)
                    Text("No notable anomalies detected")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(TechColors.textSecondary)
                    Spacer()
                }
                .padding(10)
                .background(TechColors.bgCard)
                .cornerRadius(7)
            } else {
                ForEach(events.prefix(8)) { event in eventRow(event) }
            }
        }
    }

    private func eventRow(_ event: HealthEvent) -> some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: event.severity == .critical ? "exclamationmark.octagon.fill" : event.severity == .warning ? "exclamationmark.triangle.fill" : "info.circle.fill")
                .foregroundColor(severityColor(event.severity))
                .frame(width: 16)
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(event.title)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(TechColors.textPrimary)
                    Text("· \(event.metric.rawValue)")
                        .font(.system(size: 9))
                        .foregroundColor(TechColors.textMuted)
                    Spacer()
                    TimelineView(.periodic(from: .now, by: 1)) { context in
                        Text(EnglishRelativeTime.format(event.timestamp, relativeTo: context.date))
                    }
                        .font(.system(size: 8))
                        .foregroundColor(TechColors.textMuted)
                }
                Text(event.detail)
                    .font(.system(size: 9))
                    .foregroundColor(TechColors.textSecondary)
                Text(event.recommendation)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(metricColor(event.metric))
            }
        }
        .padding(9)
        .background(TechColors.bgCard)
        .cornerRadius(7)
        .overlay(RoundedRectangle(cornerRadius: 7).stroke(severityColor(event.severity).opacity(0.25)))
    }

    private var emptyHealthState: some View {
        VStack(spacing: 6) {
            Image(systemName: "waveform.path.ecg").font(.system(size: 24)).foregroundColor(TechColors.textMuted)
            Text("No history data available").font(.system(size: 12, weight: .semibold)).foregroundColor(TechColors.textSecondary)
            Text("Keep Silivue running to build a private, on-device health summary.").font(.system(size: 9)).foregroundColor(TechColors.textMuted)
        }
        .frame(maxWidth: .infinity, minHeight: 150)
    }

    private var privacyNote: some View {
        HStack(spacing: 5) {
            Image(systemName: "lock.shield.fill")
            Text(exportMessage ?? "Analyzed locally · No account · No metric history is uploaded")
            Spacer()
        }
        .font(.system(size: 8, weight: .medium))
        .foregroundColor(TechColors.textMuted)
    }

    private func loadReport() async {
        isLoading = true
        guard let historyStore else { report = nil; isLoading = false; return }
        let now = Date()
        let start = now.addingTimeInterval(-period.duration)
        let previousStart = start.addingTimeInterval(-period.duration)
        let ids = monitorIDs
        let sampleLimit = max(1, Int(period.duration / 30))
        let loaded = await Task.detached(priority: .userInitiated) { () -> ([String: [AnyMonitorSample]], [String: [AnyMonitorSample]]) in
            var current: [String: [AnyMonitorSample]] = [:]
            var previous: [String: [AnyMonitorSample]] = [:]
            for monitorID in ids {
                current[monitorID] = (try? await historyStore.querySampled(monitorID: monitorID, from: start, to: now, maxSamples: sampleLimit)) ?? []
                previous[monitorID] = (try? await historyStore.querySampled(monitorID: monitorID, from: previousStart, to: start, maxSamples: sampleLimit)) ?? []
            }
            return (current, previous)
        }.value
        var current = loaded.0
        let previous = loaded.1
        appendLatestSamples(to: &current)
        currentSamples = current
        report = LocalHealthAnalyzer().analyze(current: current, previous: previous)
        isLoading = false
    }

    private func appendLatestSamples(to samples: inout [String: [AnyMonitorSample]]) {
        if let value = engine.latestCPU { samples["cpu", default: []].append(AnyMonitorSample(value)) }
        if let value = engine.latestMemory { samples["memory", default: []].append(AnyMonitorSample(value)) }
        if let value = engine.latestNetwork { samples["network", default: []].append(AnyMonitorSample(value)) }
        if let value = engine.latestDisk { samples["disk", default: []].append(AnyMonitorSample(value)) }
        if let value = engine.latestBattery { samples["battery", default: []].append(AnyMonitorSample(value)) }
        if let value = engine.latestTemperature { samples["temperature", default: []].append(AnyMonitorSample(value)) }
    }

    private func exportCSV() {
        let panel = NSSavePanel()
        panel.title = "Silivue — Export History"
        panel.nameFieldStringValue = "Silivue-\(period.rawValue)-history.csv"
        panel.allowedContentTypes = [.commaSeparatedText]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try HistoryCSVExporter.makeCSV(samplesByMonitor: currentSamples).write(to: url, atomically: true, encoding: .utf8)
            exportMessage = "Exported locally to \(url.lastPathComponent)"
        } catch {
            exportMessage = "Export failed. Choose a writable location and try again."
        }
    }

    private func scoreColor(_ score: Int) -> Color { score >= 85 ? TechColors.accentGreen : score >= 60 ? TechColors.accentOrange : TechColors.accentRed }
    private func severityColor(_ severity: HealthSeverity) -> Color { severity == .critical ? TechColors.accentRed : severity == .warning ? TechColors.accentOrange : TechColors.accentBlue }
    private func metricColor(_ metric: HealthMetric) -> Color {
        switch metric { case .cpu: return TechColors.accentCyan; case .memory: return TechColors.accentPurple; case .network: return TechColors.accentGreen; case .disk: return TechColors.accentTeal; case .battery: return TechColors.accentOrange; case .thermal: return TechColors.accentRed }
    }
    private func changeColor(_ metric: HealthMetric, _ change: Double) -> Color {
        if metric == .battery { return change >= 0 ? TechColors.accentGreen : TechColors.accentOrange }
        return change <= 0 ? TechColors.accentGreen : TechColors.accentOrange
    }
    private func metricValue(_ value: Double, _ unit: String) -> String {
        if unit == "B/s" { return ByteFormatter.formatSpeed(value) }
        return String(format: "%.1f%@", value, unit)
    }
}

struct MetricExplanationCard: View {
    let title: String
    let explanation: String
    let recommendation: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 10))
                .foregroundColor(color)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 10, weight: .bold)).foregroundColor(TechColors.textPrimary)
                Text(explanation).font(.system(size: 9)).foregroundColor(TechColors.textSecondary)
                Text(recommendation).font(.system(size: 9, weight: .medium)).foregroundColor(color)
            }
            Spacer()
        }
        .padding(9)
        .background(TechColors.bgCard)
        .cornerRadius(7)
        .overlay(RoundedRectangle(cornerRadius: 7).stroke(color.opacity(0.25)))
    }
}
