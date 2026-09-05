import SwiftUI
import Combine
import MonitorEngine
import DataLayer
import UIComponents
import ServiceManagement
import CoreLocation
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate, CLLocationManagerDelegate {
    var statusBarController: StatusBarController?
    let monitorEngine = MonitorEngine()
    let settings = UserDefaultsStore()
    var historyStore: SQLiteHistoryStore?
    var cancellables = Set<AnyCancellable>()
    private let locationManager = CLLocationManager()
    private var healthNotificationCoordinator: HealthNotificationCoordinator?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 菜单栏应用不显示Dock图标
        NSApp.setActivationPolicy(.accessory)
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()

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
        monitorEngine.register(TemperatureMonitor(dataProvider: ProcessInfoThermalDataProvider(), timer: DispatchRefreshTimer()))

        // 设置菜单栏控制器
        statusBarController = StatusBarController(engine: monitorEngine, settings: settings, historyStore: historyStore)
        healthNotificationCoordinator = HealthNotificationCoordinator(engine: monitorEngine, settings: settings)

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

private final class HealthNotificationCoordinator: NSObject, UNUserNotificationCenterDelegate {
    private let settings: UserDefaultsStore
    private var cancellables = Set<AnyCancellable>()
    private var highCPUStartedAt: Date?
    private var lastSent: [String: Date] = [:]
    private let cooldown: TimeInterval = 60 * 60

    init(engine: MonitorEngine, settings: UserDefaultsStore) {
        self.settings = settings
        super.init()
        // SwiftPM runs a bare executable without an application bundle. Asking
        // UserNotifications for its center there raises an Objective-C exception.
        guard Bundle.main.bundleURL.pathExtension == "app",
              let bundleID = Bundle.main.bundleIdentifier, !bundleID.isEmpty else {
            return
        }
        UNUserNotificationCenter.current().delegate = self

        settings.$healthNotificationsEnabled
            .removeDuplicates()
            .sink { enabled in
                guard enabled else { return }
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
            }
            .store(in: &cancellables)

        engine.$latestCPU.compactMap { $0 }.sink { [weak self] in self?.evaluateCPU($0) }.store(in: &cancellables)
        engine.$latestMemory.compactMap { $0 }.sink { [weak self] in self?.evaluateMemory($0) }.store(in: &cancellables)
        engine.$latestDisk.compactMap { $0 }.sink { [weak self] in self?.evaluateDisk($0) }.store(in: &cancellables)
        engine.$latestTemperature.compactMap { $0 }.sink { [weak self] in self?.evaluateThermal($0) }.store(in: &cancellables)
    }

    private func evaluateCPU(_ sample: CPUSample) {
        guard settings.healthNotificationsEnabled else { highCPUStartedAt = nil; return }
        if sample.usagePercent >= settings.cpuAlertThreshold {
            highCPUStartedAt = highCPUStartedAt ?? sample.timestamp
            if let start = highCPUStartedAt, sample.timestamp.timeIntervalSince(start) >= 120 {
                send(key: "cpu", title: "Sustained high CPU",
                     body: "CPU has stayed above " + String(Int(settings.cpuAlertThreshold)) + "% for at least 2 minutes.")
            }
        } else {
            highCPUStartedAt = nil
        }
    }

    private func evaluateMemory(_ sample: MemorySample) {
        guard settings.healthNotificationsEnabled, sample.pressureLevel != .normal else { return }
        let label = sample.pressureLevel == .critical ? "Critical" : "Elevated"
        send(key: "memory", title: label + " memory pressure",
             body: "macOS is reporting " + label.lowercased() + " memory pressure. Review active apps if performance is affected.")
    }

    private func evaluateDisk(_ sample: DiskSample) {
        guard settings.healthNotificationsEnabled else { return }
        guard let volume = sample.volumes.max(by: { $0.usagePercent < $1.usagePercent }),
              100 - volume.usagePercent <= settings.diskFreeAlertThreshold else { return }
        send(key: "disk-\(volume.mountPoint)", title: "Disk space is running low",
             body: (volume.name.isEmpty ? volume.mountPoint : volume.name) + " has " + String(Int(100 - volume.usagePercent)) + "% free space remaining.")
    }

    private func evaluateThermal(_ sample: TemperatureSample) {
        guard settings.healthNotificationsEnabled,
              sample.thermalState == .serious || sample.thermalState == .critical else { return }
        send(key: "thermal", title: "Thermal pressure detected",
             body: "macOS reports " + sample.thermalState.rawValue + " thermal pressure. Reduce heavy workloads and improve airflow.")
    }

    private func send(key: String, title: String, body: String) {
        let now = Date()
        if let last = lastSent[key], now.timeIntervalSince(last) < cooldown { return }
        lastSent[key] = now

        let content = UNMutableNotificationContent()
        content.title = "Silivue — " + title
        content.body = body
        content.sound = .default
        let request = UNNotificationRequest(identifier: "silivue.health.\(key).\(Int(now.timeIntervalSince1970))",
                                            content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}
