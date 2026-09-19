import MonitorEngine

public struct AppSettings: Equatable {
    public var refreshInterval: RefreshInterval
    public var displayMode: DisplayMode
    public var enabledMonitors: Set<String>
    public var launchAtLogin: Bool
    public var healthNotificationsEnabled: Bool
    public var cpuAlertThreshold: Double
    public var diskFreeAlertThreshold: Double
    public var language: AppLanguage

    public init(refreshInterval: RefreshInterval = .twoSeconds,
                displayMode: DisplayMode = .compact,
                enabledMonitors: Set<String> = ["cpu", "memory", "network", "disk", "battery", "temperature"],
                launchAtLogin: Bool = false,
                healthNotificationsEnabled: Bool = false,
                cpuAlertThreshold: Double = 85,
                diskFreeAlertThreshold: Double = 10,
                language: AppLanguage = .english) {
        self.refreshInterval = refreshInterval
        self.displayMode = displayMode
        self.enabledMonitors = enabledMonitors
        self.launchAtLogin = launchAtLogin
        self.healthNotificationsEnabled = healthNotificationsEnabled
        self.cpuAlertThreshold = cpuAlertThreshold
        self.diskFreeAlertThreshold = diskFreeAlertThreshold
        self.language = language
    }
}
