import AppKit
import SwiftUI
import UniformTypeIdentifiers
import MonitorEngine
import DataLayer

struct PerformanceReplayView: View {
    let historyStore: HistoryStore?
    @State private var replay: PerformanceReplay?
    @State private var isLoading = false
    @State private var exportMessage: String?

    private let duration: TimeInterval = 15 * 60
    private let monitorIDs = ["cpu", "memory", "network", "disk", "temperature"]

    var body: some View {
        DetailsScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Performance Replay")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(TechColors.textPrimary)
                        Text("Review the last 15 minutes of local system activity.")
                            .font(.system(size: 11))
                            .foregroundColor(TechColors.textSecondary)
                    }
                    Spacer()
                    Button(action: { Task { await loadReplay() } }) {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)
                    .disabled(isLoading)
                }

                if isLoading {
                    ProgressView("Analyzing local history…")
                } else if let replay {
                    replaySummary(replay)
                    findings(replay)
                    runningAppsContext
                    actions(replay)
                } else {
                    emptyState
                }
            }
            .padding(14)
        }
        .task { await loadReplay() }
    }

    private func replaySummary(_ replay: PerformanceReplay) -> some View {
        HStack(spacing: 10) {
            Image(systemName: replay.findings.isEmpty ? "checkmark.shield.fill" : "waveform.path.ecg")
                .font(.system(size: 22))
                .foregroundColor(replay.findings.isEmpty ? TechColors.accentGreen : TechColors.accentOrange)
            VStack(alignment: .leading, spacing: 2) {
                Text(replay.findings.isEmpty
                     ? AppLocalization.text("No notable system pressure")
                     : AppLocalization.format("%d item(s) need attention", replay.findings.count))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(TechColors.textPrimary)
                Text(AppLocalization.format("%d local samples analyzed · Nothing was uploaded", replay.sampleCount))
                    .font(.system(size: 10))
                    .foregroundColor(TechColors.textSecondary)
            }
            Spacer()
        }
        .padding(11)
        .background(TechColors.bgCard)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(TechColors.accentCyan.opacity(0.25)))
        .cornerRadius(8)
    }

    private func findings(_ replay: PerformanceReplay) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("WHAT HAPPENED")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(TechColors.textMuted)
            if replay.findings.isEmpty {
                Text("Silivue did not detect high CPU, memory pressure, low disk space, thermal pressure, or a large network spike in this window.")
                    .font(.system(size: 11))
                    .foregroundColor(TechColors.textSecondary)
            } else {
                ForEach(replay.findings) { finding in
                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Text(finding.title).font(.system(size: 12, weight: .bold))
                            Spacer()
                            Text(AppLocalization.text(finding.severity == .critical ? "CRITICAL" : finding.severity == .warning ? "WARNING" : "INFO"))
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(color(for: finding.severity))
                        }
                        Text(finding.evidence).font(.system(size: 11)).foregroundColor(TechColors.textSecondary)
                        Text(finding.nextStep).font(.system(size: 11, weight: .medium)).foregroundColor(color(for: finding.severity))
                    }
                    .padding(10)
                    .background(TechColors.bgCard)
                    .overlay(RoundedRectangle(cornerRadius: 7).stroke(color(for: finding.severity).opacity(0.25)))
                    .cornerRadius(7)
                }
            }
        }
    }

    private var runningAppsContext: some View {
        let apps = NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular && $0.localizedName != nil }
            .map { RunningAppContext(name: $0.localizedName ?? "Unknown", bundleIdentifier: $0.bundleIdentifier) }
        let names = apps.prefix(8).map(\.name)
        let workloads = DeveloperWorkloadClassifier().classify(apps)
        return VStack(alignment: .leading, spacing: 5) {
            Text("WORKLOAD CONTEXT (NOT ATTRIBUTION)")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(TechColors.textMuted)
            if !workloads.isEmpty {
                HStack(spacing: 5) {
                    ForEach(workloads) { workload in
                        Text(workload.title)
                            .font(.system(size: 9, weight: .semibold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(TechColors.accentPurple.opacity(0.15))
                            .foregroundColor(TechColors.accentPurple)
                            .cornerRadius(4)
                    }
                }
                Text("Detected from public app metadata only. It does not mean these workloads caused an event.")
                    .font(.system(size: 9))
                    .foregroundColor(TechColors.textMuted)
            }
            Text(names.isEmpty ? AppLocalization.text("No foreground apps are currently listed.") : names.joined(separator: " · "))
                .font(.system(size: 10))
                .foregroundColor(TechColors.textSecondary)
            Text("Silivue does not infer that any listed app caused an event. Use Activity Monitor for per-process resource data.")
                .font(.system(size: 9))
                .foregroundColor(TechColors.textMuted)
        }
        .padding(10)
        .background(TechColors.bgSecondary)
        .cornerRadius(7)
    }

    private func actions(_ replay: PerformanceReplay) -> some View {
        HStack(spacing: 8) {
            Button(action: openActivityMonitor) {
                Label("Open Activity Monitor", systemImage: "waveform.path.ecg.rectangle")
            }
            .buttonStyle(.bordered)
            Button(action: { export(replay) }) {
                Label("Export Private Report", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(.bordered)
            Spacer()
        }
        .overlay(alignment: .bottomLeading) {
            if let exportMessage {
                Text(exportMessage).font(.system(size: 9)).foregroundColor(TechColors.textMuted).offset(y: 18)
            }
        }
        .padding(.bottom, exportMessage == nil ? 0 : 18)
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Not enough local history yet").font(.system(size: 13, weight: .bold)).foregroundColor(TechColors.textPrimary)
            Text("Keep Silivue running for a few minutes, then return here to replay recent system activity.")
                .font(.system(size: 11)).foregroundColor(TechColors.textSecondary)
        }
        .padding(12)
        .background(TechColors.bgCard)
        .cornerRadius(8)
    }

    private func loadReplay() async {
        guard let historyStore else { return }
        isLoading = true
        let end = Date()
        let start = end.addingTimeInterval(-duration)
        let loaded = await Task.detached(priority: .userInitiated) { () -> [String: [AnyMonitorSample]] in
            var samples: [String: [AnyMonitorSample]] = [:]
            for id in monitorIDs {
                samples[id] = (try? await historyStore.querySampled(monitorID: id, from: start, to: end, maxSamples: 180)) ?? []
            }
            return samples
        }.value
        replay = PerformanceReplayAnalyzer().analyze(samples: loaded, from: start, to: end)
        isLoading = false
    }

    private func openActivityMonitor() {
        NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Utilities/Activity Monitor.app"))
    }

    private func export(_ replay: PerformanceReplay) {
        let panel = NSSavePanel()
        panel.title = AppLocalization.text("Silivue — Export Private Diagnostic Report")
        panel.nameFieldStringValue = "Silivue-performance-replay.md"
        panel.allowedContentTypes = [.plainText]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try DiagnosticReportExporter.makeMarkdown(replay).write(to: url, atomically: true, encoding: .utf8)
            exportMessage = AppLocalization.format("Exported locally to %@", url.lastPathComponent)
        } catch {
            exportMessage = AppLocalization.text("Export failed. Choose a writable location and try again.")
        }
    }

    private func color(for severity: ReplayFinding.Severity) -> Color {
        switch severity {
        case .info: return TechColors.accentBlue
        case .warning: return TechColors.accentOrange
        case .critical: return TechColors.accentRed
        }
    }
}
