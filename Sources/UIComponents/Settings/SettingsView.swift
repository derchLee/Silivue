import SwiftUI
import MonitorEngine
import DataLayer

public struct SettingsView: View {
    @ObservedObject var settings: UserDefaultsStore
    let historyStore: HistoryStore?

    @State private var selectedTab = 0

    private let tabItems = [
        ("General", "gearshape.fill", TechColors.accentCyan),
        ("Display", "paintbrush.fill", TechColors.accentPurple),
        ("History", "clock.arrow.circlepath", TechColors.accentGreen)
    ]

    public init(settings: UserDefaultsStore, historyStore: HistoryStore? = nil) {
        self.settings = settings
        self.historyStore = historyStore
    }

    public var body: some View {
        ZStack {
            TechColors.bgPrimary
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // 自定义 Tab 栏
                HStack(spacing: 6) {
                    ForEach(Array(tabItems.enumerated()), id: \.offset) { idx, item in
                        let (title, icon, color) = item
                        tabButton(title: title, icon: icon, color: color, index: idx)
                    }
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.top, 12)
                .padding(.bottom, 8)
                .background(TechColors.bgSecondary)
                .overlay(
                    Rectangle()
                        .fill(TechColors.borderSubtle)
                        .frame(height: 1),
                    alignment: .bottom
                )

                // Tab 内容
                Group {
                    switch selectedTab {
                    case 0: GeneralSettingsView(settings: settings)
                    case 1: DisplaySettingsView(settings: settings)
                    case 2: HistorySettingsView(settings: settings, historyStore: historyStore)
                    default: EmptyView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private func tabButton(title: String, icon: String, color: Color, index: Int) -> some View {
        Button(action: { selectedTab = index }) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(selectedTab == index ? color : TechColors.textMuted)
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(selectedTab == index ? TechColors.textPrimary : TechColors.textMuted)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(selectedTab == index ? color.opacity(0.15) : TechColors.bgHover)
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(selectedTab == index ? color.opacity(0.4) : TechColors.borderSubtle, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
