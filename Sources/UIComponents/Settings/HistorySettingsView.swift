import SwiftUI
import MonitorEngine
import DataLayer

public struct HistorySettingsView: View {
    @ObservedObject var settings: UserDefaultsStore
    let historyStore: HistoryStore?

    @State private var cpuCount: Int = 0
    @State private var memoryCount: Int = 0
    @State private var networkCount: Int = 0

    public init(settings: UserDefaultsStore, historyStore: HistoryStore? = nil) {
        self.settings = settings
        self.historyStore = historyStore
    }

    public var body: some View {
        ZStack {
            TechColors.bgPrimary
                .ignoresSafeArea()

            VStack(spacing: 16) {
                sectionHeader("History", icon: "clock.arrow.circlepath", color: TechColors.accentGreen)

                settingCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Samples")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(TechColors.textSecondary)

                        VStack(spacing: 6) {
                            sampleRow("CPU", count: cpuCount, color: TechColors.accentCyan)
                            sampleRow("Memory", count: memoryCount, color: TechColors.accentPurple)
                            sampleRow("Network", count: networkCount, color: TechColors.accentGreen)
                        }
                    }

                settingCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Maintenance")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(TechColors.textSecondary)

                        HStack(spacing: 12) {
                            Button(action: pruneData) {
                                Text("Prune Old Data")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(TechColors.accentCyan)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(TechColors.accentCyan.opacity(0.15))
                                    .cornerRadius(6)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(TechColors.accentCyan.opacity(0.4), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)

                            Button(action: clearAllData) {
                                Text("Clear All")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(TechColors.accentRed)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(TechColors.accentRed.opacity(0.15))
                                    .cornerRadius(6)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(TechColors.accentRed.opacity(0.4), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Spacer()
                }
            }
            .padding(16)
        }
        .onAppear { loadCounts() }
    }

    private func sectionHeader(_ title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 28, height: 28)
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(color)
            }
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(TechColors.textPrimary)
            Spacer()
        }
    }

    private func sampleRow(_ label: String, count: Int, color: Color) -> some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(TechColors.textSecondary)
            Spacer()
            Text("\(count)")
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(TechColors.textPrimary)
        }
    }

    private func settingCard(@ViewBuilder content: () -> some View) -> some View {
        content()
            .padding(12)
            .background(TechColors.bgCard)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(TechColors.borderSubtle, lineWidth: 1)
            )
    }

    private func loadCounts() {
        guard let store = historyStore else { return }
        Task {
            cpuCount = (try? await store.sampleCount(monitorID: "cpu")) ?? 0
            memoryCount = (try? await store.sampleCount(monitorID: "memory")) ?? 0
            networkCount = (try? await store.sampleCount(monitorID: "network")) ?? 0
        }
    }

    private func pruneData() {
        guard let store = historyStore else { return }
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        Task {
            try? await store.delete(olderThan: cutoff)
            loadCounts()
        }
    }

    private func clearAllData() {
        guard let store = historyStore else { return }
        let cutoff = Date.distantFuture
        Task {
            try? await store.delete(olderThan: cutoff)
            loadCounts()
        }
    }

}
