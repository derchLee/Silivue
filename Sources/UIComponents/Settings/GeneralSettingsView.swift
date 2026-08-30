import SwiftUI
import MonitorEngine
import DataLayer

public struct GeneralSettingsView: View {
    @ObservedObject var settings: UserDefaultsStore

    public init(settings: UserDefaultsStore) {
        self.settings = settings
    }

    public var body: some View {
        ZStack {
            TechColors.bgPrimary
                .ignoresSafeArea()

            VStack(spacing: 16) {
                // 标题区
                sectionHeader("General", icon: "gearshape.fill", color: TechColors.accentCyan)

                // 刷新频率
                settingCard {
                    HStack {
                        Text("Refresh Interval")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(TechColors.textPrimary)
                        Spacer()
                        Picker("", selection: $settings.refreshInterval) {
                            ForEach(RefreshInterval.allCases, id: \.self) { interval in
                                Text(interval.displayName).tag(interval)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 140)
                    }
                }

                // 开机自启
                settingCard {
                    HStack {
                        Text("Launch at Login")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(TechColors.textPrimary)
                        Spacer()
                        Toggle("", isOn: $settings.launchAtLogin)
                            .toggleStyle(.switch)
                            .labelsHidden()
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
