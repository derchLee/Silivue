import Combine
import Foundation
import MonitorEngine
@testable import DataLayer

final class MockSettingsStore: SettingsStore {
    var refreshInterval: RefreshInterval = .twoSeconds
    var displayMode: DisplayMode = .compact
    var enabledMonitors: Set<String> = ["cpu", "memory", "network"]
    var launchAtLogin: Bool = false

    let subject = PassthroughSubject<AppSettings, Never>()
    var settingsChanged: AnyPublisher<AppSettings, Never> {
        subject.eraseToAnyPublisher()
    }

    func simulateChange() {
        subject.send(AppSettings(
            refreshInterval: refreshInterval,
            displayMode: displayMode,
            enabledMonitors: enabledMonitors,
            launchAtLogin: launchAtLogin
        ))
    }
}
