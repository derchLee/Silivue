import MonitorEngine

public struct AppSettings: Equatable {
    public var refreshInterval: RefreshInterval
    public var displayMode: DisplayMode
    public var enabledMonitors: Set<String>
    public var launchAtLogin: Bool

    public init(refreshInterval: RefreshInterval = .twoSeconds,
                displayMode: DisplayMode = .compact,
                enabledMonitors: Set<String> = ["cpu", "memory", "network", "disk", "battery", "temperature", "process"],
                launchAtLogin: Bool = false) {
        self.refreshInterval = refreshInterval
        self.displayMode = displayMode
        self.enabledMonitors = enabledMonitors
        self.launchAtLogin = launchAtLogin
    }
}
