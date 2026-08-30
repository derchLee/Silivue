import SwiftUI
import MonitorEngine
import DataLayer

public struct DisplaySettingsView: View {
    @ObservedObject var settings: UserDefaultsStore

    public init(settings: UserDefaultsStore) {
        self.settings = settings
    }

    public var body: some View {
        ZStack {
            TechColors.bgPrimary
                .ignoresSafeArea()

            VStack(spacing: 16) {
                sectionHeader("Display", icon: "paintbrush.fill", color: TechColors.accentPurple)

                settingCard {
                    HStack {
                        Text("Display Mode")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(TechColors.textPrimary)
                        Spacer()
                        Picker("", selection: $settings.displayMode) {
                            ForEach(DisplayMode.allCases, id: \.self) { mode in
                                Text(mode.displayName).tag(mode)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 140)
                    }
                }

                // 监控项开关
                settingCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Show in Menu Bar")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(TechColors.textSecondary)
                            .padding(.bottom, 2)

                        HStack(spacing: 0) {
                            monitorToggleCol(labels: [("CPU", "cpu"), ("Memory", "memory"), ("Network", "network")])
                            Spacer()
                            monitorToggleCol(labels: [("Disk", "disk"), ("Battery", "battery"), ("Temp", "temperature")])
                        }
                    }
                }

                Spacer()
            }
            .padding(16)
        }
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

    private func monitorToggleCol(labels: [(String, String)]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(labels, id: \.1) { label, id in
                Toggle(isOn: monitorToggle(for: id)) {
                    Text(label)
                    .font(.system(size: 11))
                    .foregroundColor(TechColors.textPrimary)
                }
                .toggleStyle(.switch)
            }
        }
    }

    private func monitorToggle(for id: String) -> Binding<Bool> {
        Binding(
            get: { settings.enabledMonitors.contains(id) },
            set: { isOn in
                if isOn { settings.enabledMonitors.insert(id) }
                else { settings.enabledMonitors.remove(id) }
            }
        )
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
}
