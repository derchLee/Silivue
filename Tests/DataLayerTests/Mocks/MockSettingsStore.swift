import Combine
import Foundation
import MonitorEngine
@testable import DataLayer

final class MockSettingsStore: SettingsStore {
    var refreshInterval: RefreshInterval = .twoSeconds
    var displayMode: DisplayMode = .compact
    var enabledMonitors: Set<String> = ["cpu", "memory", "network"]
    var launchAtLogin: Bool = false
    var healthNotificationsEnabled: Bool = false
    var cpuAlertThreshold: Double = 85
    var diskFreeAlertThreshold: Double = 10

    let subject = PassthroughSubject<AppSettings, Never>()
    var settingsChanged: AnyPublisher<AppSettings, Never> {
        subject.eraseToAnyPublisher()
    }

    func simulateChange() {
        subject.send(AppSettings(
            refreshInterval: refreshInterval,
            displayMode: displayMode,
            enabledMonitors: enabledMonitors,
            launchAtLogin: launchAtLogin,
            healthNotificationsEnabled: healthNotificationsEnabled,
            cpuAlertThreshold: cpuAlertThreshold,
            diskFreeAlertThreshold: diskFreeAlertThreshold
        ))
    }
}
