import Combine
import Foundation
import MonitorEngine

public final class UserDefaultsStore: SettingsStore, ObservableObject {
    private let defaults: UserDefaults
    private let subject = PassthroughSubject<AppSettings, Never>()
    private var cancellables = Set<AnyCancellable>()

    public var settingsChanged: AnyPublisher<AppSettings, Never> {
        subject.eraseToAnyPublisher()
    }

    @Published public var refreshInterval: RefreshInterval {
        didSet {
            defaults.set(refreshInterval.rawValue, forKey: Key.refreshInterval)
            publishChange()
        }
    }

    @Published public var displayMode: DisplayMode {
        didSet {
            defaults.set(displayMode.rawValue, forKey: Key.displayMode)
            publishChange()
        }
    }

    @Published public var enabledMonitors: Set<String> {
        didSet {
            defaults.set(Array(enabledMonitors), forKey: Key.enabledMonitors)
            publishChange()
        }
    }

    @Published public var launchAtLogin: Bool {
        didSet {
            defaults.set(launchAtLogin, forKey: Key.launchAtLogin)
            publishChange()
        }
    }

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        // 从UserDefaults读取存储的值
        if let raw = defaults.object(forKey: Key.refreshInterval) as? Double,
           let interval = RefreshInterval(rawValue: raw) {
            self.refreshInterval = interval
        } else {
            self.refreshInterval = .twoSeconds
        }

        if let raw = defaults.string(forKey: Key.displayMode),
           let mode = DisplayMode(rawValue: raw) {
            self.displayMode = mode
        } else {
            self.displayMode = .compact
        }

        if let array = defaults.stringArray(forKey: Key.enabledMonitors) {
            self.enabledMonitors = Set(array)
        } else {
            self.enabledMonitors = ["cpu", "memory", "network", "disk", "battery", "temperature", "process"]
        }

        self.launchAtLogin = defaults.bool(forKey: Key.launchAtLogin)
    }

    private func publishChange() {
        subject.send(AppSettings(
            refreshInterval: refreshInterval,
            displayMode: displayMode,
            enabledMonitors: enabledMonitors,
            launchAtLogin: launchAtLogin
        ))
    }

    private enum Key {
        static let refreshInterval = "refreshInterval"
        static let displayMode = "displayMode"
        static let enabledMonitors = "enabledMonitors"
        static let launchAtLogin = "launchAtLogin"
    }
}