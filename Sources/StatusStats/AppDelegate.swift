import SwiftUI
import Combine
import MonitorEngine
import DataLayer
import UIComponents
import ServiceManagement

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarController: StatusBarController?
    let monitorEngine = MonitorEngine()
    let settings = UserDefaultsStore()
    var historyStore: SQLiteHistoryStore?
    var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 菜单栏应用不显示Dock图标
        NSApp.setActivationPolicy(.accessory)

        // 初始化历史存储
        if let store = try? SQLiteHistoryStore() {
            historyStore = store
            monitorEngine.setHistoryStore(store)
            let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
            Task { try? await store.delete(olderThan: cutoff) }
        }

        // 注册监控器
        monitorEngine.register(CPUMonitor(dataProvider: MachCPUDataProvider(), timer: DispatchRefreshTimer()))
        monitorEngine.register(MemoryMonitor(dataProvider: MachMemoryDataProvider(), timer: DispatchRefreshTimer()))
        monitorEngine.register(NetworkMonitor(dataProvider: DarwinNetworkDataProvider(), connectionProvider: CoreWLANDataProvider(), timer: DispatchRefreshTimer()))
        monitorEngine.register(DiskMonitor(dataProvider: FoundationDiskDataProvider(), timer: DispatchRefreshTimer()))
        monitorEngine.register(BatteryMonitor(dataProvider: IOKitBatteryDataProvider(), timer: DispatchRefreshTimer()))
        monitorEngine.register(TemperatureMonitor(dataProvider: IOKitSMCDataProvider(), timer: DispatchRefreshTimer()))
        monitorEngine.register(ProcessMonitor(dataProvider: LibprocDataProvider(), timer: DispatchRefreshTimer()))

        // 设置菜单栏控制器
        statusBarController = StatusBarController(engine: monitorEngine, settings: settings, historyStore: historyStore)

        // 启动监控
        startMonitoring()

        // 监听刷新间隔变更
        settings.$refreshInterval
            .dropFirst()
            .sink { [weak self] _ in
                self?.restartMonitoring()
            }
            .store(in: &cancellables)

        // 监听监控器开关变更
        settings.$enabledMonitors
            .dropFirst()
            .sink { [weak self] _ in
                self?.restartMonitoring()
            }
            .store(in: &cancellables)

        // 监听开机自启变更
        settings.$launchAtLogin
            .dropFirst()
            .sink { [weak self] enabled in
                self?.updateLaunchAtLogin(enabled: enabled)
            }
            .store(in: &cancellables)

        // 启动时同步开机自启状态
        if settings.launchAtLogin {
            updateLaunchAtLogin(enabled: true)
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        monitorEngine.stopAll()
    }

    private func restartMonitoring() {
        monitorEngine.stopAll()
        startMonitoring()
    }

    private func startMonitoring() {
        monitorEngine.startAll(interval: settings.refreshInterval, enabledMonitors: settings.enabledMonitors)
    }

    private func updateLaunchAtLogin(enabled: Bool) {
        // SMAppService needs a real .app bundle; Xcode's SwiftPM run can lack a bundle identifier.
        guard Bundle.main.bundleIdentifier != nil,
              Bundle.main.bundleURL.pathExtension == "app" else {
            return
        }

        if enabled {
            try? SMAppService.mainApp.register()
        } else {
            try? SMAppService.mainApp.unregister()
        }
    }
}
