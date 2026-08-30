import Combine
import MonitorEngine
import Foundation

public protocol SettingsStore: AnyObject {
    var refreshInterval: RefreshInterval { get set }
    var displayMode: DisplayMode { get set }
    var enabledMonitors: Set<String> { get set }
    var launchAtLogin: Bool { get set }
    var settingsChanged: AnyPublisher<AppSettings, Never> { get }
}
