import SwiftUI
import Combine
import MonitorEngine
import DataLayer
import UIComponents


/// 管理NSStatusItem，通过Combine订阅MonitorEngine实时更新菜单栏文字
class StatusBarController: NSObject {
    private let engine: MonitorEngine
    private let settings: UserDefaultsStore
    private let historyStore: HistoryStore?
    private let statusItem: NSStatusItem
    private let popover: NSPopover
    private var settingsWindow: NSWindow?
    private var moreDetailsWindowController: MoreDetailsWindowController?
    private var cancellables = Set<AnyCancellable>()

    init(engine: MonitorEngine, settings: UserDefaultsStore, historyStore: HistoryStore? = nil) {
        self.engine = engine
        self.settings = settings
        self.historyStore = historyStore
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.popover = NSPopover()
        super.init()

        popover.contentSize = NSSize(width: 320, height: 560)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: PopoverView(
                engine: engine,
                settings: settings,
                historyStore: historyStore,
                onSettingsTapped: { [weak self] in self?.openSettings() },
                onMoreTapped: { [weak self] in self?.openMoreDetails() }
            )
        )

        if let button = statusItem.button {
            button.action = #selector(togglePopover)
            button.target = self
            updateButtonTitle()
        }

        // 菜单栏显示项订阅
        engine.$latestCPU
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.updateButtonTitle() }
            .store(in: &cancellables)

        engine.$latestMemory
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.updateButtonTitle() }
            .store(in: &cancellables)

        engine.$latestNetwork
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.updateButtonTitle() }
            .store(in: &cancellables)

        engine.$latestBattery
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.updateButtonTitle() }
            .store(in: &cancellables)

        engine.$latestTemperature
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.updateButtonTitle() }
            .store(in: &cancellables)

        settings.$displayMode
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.updateButtonTitle() }
            .store(in: &cancellables)

        settings.$enabledMonitors
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.updateButtonTitle() }
            .store(in: &cancellables)
    }

    // MARK: - 菜单栏文字更新

    private func updateButtonTitle() {
        var parts: [String] = []

        // CPU
        if settings.enabledMonitors.contains("cpu"), let cpu = engine.latestCPU {
            switch settings.displayMode {
            case .compact:
                parts.append("CPU \(Int(cpu.usagePercent))%")
            case .icon:
                parts.append("⬢\(Int(cpu.usagePercent))")
            case .numeric:
                parts.append("CPU:\(Int(cpu.usagePercent))%")
            }
        }

        // Memory
        if settings.enabledMonitors.contains("memory"), let mem = engine.latestMemory {
            switch settings.displayMode {
            case .compact:
                parts.append("RAM \(Int(mem.usagePercent))%")
            case .icon:
                parts.append("⬡\(Int(mem.usagePercent))")
            case .numeric:
                parts.append("RAM:\(ByteFormatter.format(mem.usedBytes))")
            }
        }

        // Network
        if settings.enabledMonitors.contains("network"), let net = engine.latestNetwork {
            switch settings.displayMode {
            case .compact:
                parts.append("↑\(ByteFormatter.formatSpeed(net.uploadBytesPerSec)) ↓\(ByteFormatter.formatSpeed(net.downloadBytesPerSec))")
            case .icon:
                parts.append("⬆\(ByteFormatter.formatSpeed(net.uploadBytesPerSec))")
            case .numeric:
                parts.append("↑\(ByteFormatter.formatSpeed(net.uploadBytesPerSec)) ↓\(ByteFormatter.formatSpeed(net.downloadBytesPerSec))")
            }
        }

        // Battery（无电池Mac不显示）
        if settings.enabledMonitors.contains("battery"), let bat = engine.latestBattery, bat.healthPercent > 0 {
            switch settings.displayMode {
            case .compact:
                parts.append("BAT \(Int(bat.chargePercent))%")
            case .icon:
                parts.append(bat.isCharging ? "BAT+\(Int(bat.chargePercent))" : "BAT\(Int(bat.chargePercent))")
            case .numeric:
                parts.append("BAT:\(Int(bat.chargePercent))%")
            }
        }

        // Public thermal state; Apple does not expose sensor temperatures to App Store apps.
        if settings.enabledMonitors.contains("temperature"), let temp = engine.latestTemperature {
            let state: String
            switch temp.thermalState {
            case .nominal: state = "OK"
            case .fair: state = "WARM"
            case .serious: state = "HOT"
            case .critical: state = "CRIT"
            }
            switch settings.displayMode {
            case .compact:
                parts.append("TEMP \(state)")
            case .icon:
                parts.append("TMP\(state)")
            case .numeric:
                parts.append("TEMP:\(state)")
            }
        }

        let title = parts.isEmpty ? "Silivue" : parts.joined(separator: "  ")

        if let button = statusItem.button {
            let attributedString = NSAttributedString(
                string: title,
                attributes: [
                    .font: NSFont.monospacedSystemFont(ofSize: 12, weight: .medium),
                    .foregroundColor: NSColor.labelColor
                ]
            )
            button.attributedTitle = attributedString
        }
    }

    @objc private func togglePopover() {
        if let button = statusItem.button {
            if popover.isShown {
                popover.performClose(nil)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
        }
    }

    // MARK: - 设置窗口

    private func openSettings() {
        popover.performClose(nil)

        if let existing = settingsWindow, existing.isVisible {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let settingsView = SettingsView(settings: settings, historyStore: historyStore)
        let hostingController = NSHostingController(rootView: settingsView)

        let window = NSWindow(contentViewController: hostingController)
        window.title = "Silivue — Settings"
        window.styleMask = [.titled, .closable]
        window.setContentSize(NSSize(width: 420, height: 380))
        window.center()
        window.isReleasedWhenClosed = false
        window.delegate = self

        settingsWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - 详情窗口

    private func openMoreDetails() {
        popover.performClose(nil)

        if moreDetailsWindowController == nil {
            moreDetailsWindowController = MoreDetailsWindowController(
                engine: engine,
                settings: settings,
                historyStore: historyStore,
                statusBarController: self
            )
        }
        moreDetailsWindowController?.show()
    }
}

// MARK: - NSWindowDelegate

extension StatusBarController: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        if let window = notification.object as? NSWindow {
            if window === settingsWindow {
                settingsWindow = nil
            }
            if window === moreDetailsWindowController?.window {
                moreDetailsWindowController = nil
            }
        }
    }
}
