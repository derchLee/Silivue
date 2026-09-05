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
                        Picker("Refresh Interval", selection: $settings.refreshInterval) {
                            ForEach(RefreshInterval.allCases, id: \.self) { interval in
                                Text(interval.displayName).tag(interval)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                        .controlSize(.regular)
                        .frame(width: 140)
                    }
                }

                settingCard {
                    VStack(spacing: 10) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Health Alerts")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(TechColors.textPrimary)
                                Text("Local notifications for sustained CPU, memory, disk, and thermal issues")
                                    .font(.system(size: 9))
                                    .foregroundColor(TechColors.textSecondary)
                            }
                            Spacer()
                            Toggle("", isOn: $settings.healthNotificationsEnabled)
                                .toggleStyle(.switch)
                                .labelsHidden()
                        }

                        if settings.healthNotificationsEnabled {
                            Divider().overlay(TechColors.borderSubtle)
                            HStack {
                                Text("CPU alert")
                                    .font(.system(size: 10))
                                    .foregroundColor(TechColors.textSecondary)
                                Spacer()
                                Picker("", selection: $settings.cpuAlertThreshold) {
                                    Text("75%").tag(75.0)
                                    Text("85%").tag(85.0)
                                    Text("95%").tag(95.0)
                                }
                                .labelsHidden()
                                .frame(width: 82)

                                Text("Free disk")
                                    .font(.system(size: 10))
                                    .foregroundColor(TechColors.textSecondary)
                                Picker("", selection: $settings.diskFreeAlertThreshold) {
                                    Text("5%").tag(5.0)
                                    Text("10%").tag(10.0)
                                    Text("15%").tag(15.0)
                                }
                                .labelsHidden()
                                .frame(width: 82)
                            }
                        }
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
