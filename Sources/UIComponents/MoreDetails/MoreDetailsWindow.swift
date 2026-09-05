import AppKit
import SwiftUI
import Charts
import MonitorEngine
import DataLayer

// MARK: - 详情窗口控制器

public class MoreDetailsWindowController: NSObject, NSWindowDelegate {
    public private(set) weak var window: NSWindow?
    private let engine: MonitorEngine
    private let settings: UserDefaultsStore
    private let historyStore: HistoryStore?

    public init(engine: MonitorEngine, settings: UserDefaultsStore, historyStore: HistoryStore?, statusBarController: AnyObject? = nil) {
        self.engine = engine
        self.settings = settings
        self.historyStore = historyStore
        super.init()
    }

    public func show() {
        if let existing = window, existing.isVisible {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let contentView = MoreDetailsContainerView(
            engine: engine,
            settings: settings,
            historyStore: historyStore
        )
        let hostingController = NSHostingController(rootView: contentView)

        let window = NSWindow(contentViewController: hostingController)
        window.title = "Silivue — Details"
        window.styleMask = [.titled, .closable, .resizable, .miniaturizable]
        window.setContentSize(NSSize(width: 750, height: 500))
        window.center()
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.minSize = NSSize(width: 640, height: 380)

        self.window = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    public func windowWillClose(_ notification: Notification) {
        if let w = notification.object as? NSWindow, w === window {
            window = nil
        }
    }
}

// MARK: - 主容器视图

struct MoreDetailsContainerView: View {
    @ObservedObject var engine: MonitorEngine
    let settings: SettingsStore
    let historyStore: HistoryStore?

    @State private var selectedTab = 0

    private let tabs = ["Health", "CPU", "Memory", "Network", "Disk"]
    private let tabColors: [Color] = [
        TechColors.accentGreen,
        TechColors.accentCyan,
        TechColors.accentPurple,
        TechColors.accentGreen,
        TechColors.accentTeal
    ]

    var body: some View {
        ZStack {
            TechColors.bgPrimary
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // 顶部标题栏
                moreHeader

                // Tab 按钮行
                HStack(spacing: 4) {
                    ForEach(0..<tabs.count, id: \.self) { i in
                        TechTabButton(
                            title: tabs[i],
                            icon: tabIcon(for: i),
                            color: tabColors[i],
                            isSelected: selectedTab == i,
                            action: { selectedTab = i }
                        )
                    }
                    Spacer()
                    Button(action: openActivityMonitor) {
                        Label("Open Activity Monitor", systemImage: "waveform.path.ecg.rectangle")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(TechColors.accentBlue)
                            .padding(.horizontal, 9)
                            .frame(height: 26)
                            .background(TechColors.accentBlue.opacity(0.12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(TechColors.accentBlue.opacity(0.45), lineWidth: 1)
                            )
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    .help("Open Apple's Activity Monitor")
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .padding(.bottom, 4)
                .background(TechColors.bgSecondary)
                .overlay(
                    Rectangle()
                        .fill(TechColors.accentCyan.opacity(0.15))
                        .frame(height: 1),
                    alignment: .bottom
                )

                // Tab 内容区
                Group {
                    switch selectedTab {
                    case 0: HealthDashboardView(engine: engine, historyStore: historyStore)
                    case 1: CPUMoreTab(engine: engine, historyStore: historyStore)
                    case 2: MemoryMoreTab(engine: engine, historyStore: historyStore)
                    case 3: NetworkMoreTab(engine: engine, historyStore: historyStore)
                    case 4: DiskMoreTab(engine: engine)
                    default: EmptyView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .environment(\.locale, Locale(identifier: "en_US"))
        .preferredColorScheme(.dark)
    }

    private var moreHeader: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(TechColors.accentCyan.opacity(0.15))
                    .frame(width: 26, height: 26)
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(TechColors.accentCyan)
            }

            Text("Silivue")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(TechColors.textPrimary)

            Text("Details")
                .font(.system(size: 12))
                .foregroundColor(TechColors.textMuted)

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(TechColors.bgSecondary)
    }

    private func tabIcon(for index: Int) -> String {
        switch index {
        case 0: return "heart.text.square"
        case 1: return "cpu"
        case 2: return "memorychip"
        case 3: return "network"
        case 4: return "internaldrive"
        default: return "chart.bar"
        }
    }

    private func openActivityMonitor() {
        let url = URL(fileURLWithPath: "/System/Applications/Utilities/Activity Monitor.app")
        NSWorkspace.shared.open(url)
    }
}

// MARK: - CPU Tab

struct CPUMoreTab: View {
    @ObservedObject var engine: MonitorEngine
    let historyStore: HistoryStore?

    var body: some View {
        DetailsScrollView {
            VStack(spacing: 12) {
                if let cpu = engine.latestCPU {
                    metricMainCard(
                        title: "CPU Usage",
                        icon: "cpu",
                        iconColor: TechColors.accentCyan,
                        mainValue: "\(Int(cpu.usagePercent))%",
                        mainColor: TechColors.accentCyan,
                        extras: cpuExtraInfo(cpu)
                    )

                    // 细分指标
                    HStack(spacing: 8) {
                        cpuChip("User", "\(Int(cpu.userPercent))%", TechColors.accentCyan)
                        cpuChip("System", "\(Int(cpu.systemPercent))%", TechColors.accentPurple)
                        cpuChip("Idle", "\(Int(cpu.idlePercent))%", TechColors.textMuted)
                        cpuChip("Cores", "\(cpu.coreCount)", TechColors.textSecondary)
                    }

                    MetricExplanationCard(
                        title: cpu.usagePercent >= 80 ? "High processor load" : "CPU load looks normal",
                        explanation: "CPU usage combines work performed by apps and macOS across all cores.",
                        recommendation: cpu.usagePercent >= 80 ? "If this persists, open Activity Monitor to find the busiest app." : "Short spikes are normal when launching apps or completing background work.",
                        color: cpu.usagePercent >= 80 ? TechColors.accentOrange : TechColors.accentCyan
                    )

                    // 24h 图表
                    chartCard(
                        title: "24h History",
                        color: TechColors.accentCyan
                    ) {
                        HistoryChartView24h(
                            monitorID: "cpu",
                            valueExtractor: { $0.cpu?.usagePercent },
                            color: TechColors.accentCyan,
                            historyStore: historyStore
                        )
                    }
                } else {
                    emptyState("No CPU data available")
                }
            }
            .padding(12)
        }
        .background(TechColors.bgPrimary)
    }

    private func cpuExtraInfo(_ cpu: CPUSample) -> [(String, String)] {
        var items: [(String, String)] = []
        if let freq = cpu.frequencyGHz {
            items.append(("Frequency", String(format: "%.1f GHz", freq)))
        }
        if (cpu.performanceCoreCount ?? 0) > 0 {
            items.append(("Cores", "\(cpu.performanceCoreCount ?? 0)+ \(cpu.efficiencyCoreCount ?? 0)"))
        }
        return items
    }

    private func cpuChip(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(TechColors.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(TechColors.bgCard)
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(TechColors.borderSubtle, lineWidth: 1)
        )
    }
}

// MARK: - Memory Tab

struct MemoryMoreTab: View {
    @ObservedObject var engine: MonitorEngine
    let historyStore: HistoryStore?

    var body: some View {
        DetailsScrollView {
            VStack(spacing: 12) {
                if let mem = engine.latestMemory {
                    metricMainCard(
                        title: "Memory Usage",
                        icon: "memorychip",
                        iconColor: TechColors.accentPurple,
                        mainValue: "\(Int(mem.usagePercent))%",
                        mainColor: TechColors.accentPurple,
                        extras: [
                            ("Used", ByteFormatter.format(mem.usedBytes)),
                            ("Total", ByteFormatter.format(mem.totalBytes))
                        ]
                    )

                    TechProgressBar(
                        value: mem.usagePercent,
                        color: TechColors.accentPurple,
                        height: 8
                    )
                    .padding(.horizontal, 12)

                    MetricExplanationCard(
                        title: mem.pressureLevel == .normal ? "Memory pressure is normal" : "Memory pressure needs attention",
                        explanation: "Memory pressure is more meaningful than used percentage because macOS intentionally uses free RAM for caching.",
                        recommendation: mem.pressureLevel == .normal ? "High usage alone is usually fine while pressure remains normal." : "Close memory-heavy apps and check swap usage in Activity Monitor.",
                        color: mem.pressureLevel == .normal ? TechColors.accentPurple : TechColors.accentOrange
                    )

                    chartCard(
                        title: "24h History",
                        color: TechColors.accentPurple
                    ) {
                        HistoryChartView24h(
                            monitorID: "memory",
                            valueExtractor: { $0.memory?.usagePercent },
                            color: TechColors.accentPurple,
                            historyStore: historyStore
                        )
                    }
                } else {
                    emptyState("No memory data available")
                }
            }
            .padding(12)
        }
        .background(TechColors.bgPrimary)
    }
}

// MARK: - Network Tab

struct NetworkMoreTab: View {
    @ObservedObject var engine: MonitorEngine
    let historyStore: HistoryStore?

    var body: some View {
        DetailsScrollView {
            VStack(spacing: 12) {
                if let net = engine.latestNetwork {
                    // 实时速度
                    HStack(spacing: 8) {
                        networkSpeedCard(
                            label: "Upload",
                            icon: "arrow.up",
                            value: ByteFormatter.formatSpeed(net.uploadBytesPerSec),
                            color: TechColors.accentGreen
                        )
                        networkSpeedCard(
                            label: "Download",
                            icon: "arrow.down",
                            value: ByteFormatter.formatSpeed(net.downloadBytesPerSec),
                            color: TechColors.accentBlue
                        )
                    }

                    // 今日统计
                    HStack(spacing: 8) {
                        statMiniCard(label: "Today Upload", value: ByteFormatter.format(engine.dailyUploadBytes), color: TechColors.accentGreen)
                        statMiniCard(label: "Today Download", value: ByteFormatter.format(engine.dailyDownloadBytes), color: TechColors.accentBlue)
                    }

                    // Wi-Fi 信息
                    if let ssid = net.ssid {
                        HStack(spacing: 6) {
                            Image(systemName: "wifi")
                                .font(.system(size: 11))
                                .foregroundColor(TechColors.accentCyan)
                            Text(ssid)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(TechColors.textPrimary)
                            if let ip = net.localIP {
                                Text("·")
                                    .foregroundColor(TechColors.textMuted)
                                Text(ip)
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(TechColors.textSecondary)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(TechColors.bgCard)
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(TechColors.borderSubtle, lineWidth: 1)
                        )
                    }

                    MetricExplanationCard(
                        title: "Live transfer rate",
                        explanation: "These values show current upload and download throughput, not your connection's maximum speed.",
                        recommendation: "Spikes commonly come from downloads, cloud sync, backups, and video calls.",
                        color: TechColors.accentGreen
                    )

                    // 上传图表
                    chartCard(title: "Upload 24h", color: TechColors.accentGreen) {
                        HistoryChartView24h(
                            monitorID: "network",
                            valueExtractor: { $0.network?.uploadBytesPerSec },
                            color: TechColors.accentGreen,
                            historyStore: historyStore,
                            valueFormatter: { ByteFormatter.formatSpeed($0) }
                        )
                    }

                    // 下载图表
                    chartCard(title: "Download 24h", color: TechColors.accentBlue) {
                        HistoryChartView24h(
                            monitorID: "network",
                            valueExtractor: { $0.network?.downloadBytesPerSec },
                            color: TechColors.accentBlue,
                            historyStore: historyStore,
                            valueFormatter: { ByteFormatter.formatSpeed($0) }
                        )
                    }
                } else {
                    emptyState("No network data available")
                }
            }
            .padding(12)
        }
        .background(TechColors.bgPrimary)
    }

    private func networkSpeedCard(label: String, icon: String, value: String, color: Color) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(color)
                Text(label)
                    .font(.system(size: 9))
                    .foregroundColor(TechColors.textMuted)
            }
            GlowLabel(value, color: color, size: 18)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(TechColors.bgCard)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(TechColors.borderSubtle, lineWidth: 1)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(color.opacity(0.3), lineWidth: 1),
                    alignment: .top
                )
        )
    }

    private func statMiniCard(label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(TechColors.textMuted)
            GlowLabel(value, color: color, size: 13)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(TechColors.bgCard)
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(TechColors.borderSubtle, lineWidth: 1)
        )
    }
}

// MARK: - Disk Tab

struct DiskMoreTab: View {
    @ObservedObject var engine: MonitorEngine

    var body: some View {
        DetailsScrollView {
            VStack(spacing: 10) {
                if let disk = engine.latestDisk {
                    ForEach(disk.volumes) { volume in
                        diskVolumeCard(volume: volume)
                    }
                    if let fullest = disk.volumes.max(by: { $0.usagePercent < $1.usagePercent }) {
                        MetricExplanationCard(
                            title: fullest.usagePercent >= 90 ? "Disk space is critically low" : "Storage availability",
                            explanation: "macOS needs free space for updates, swap, caches, and temporary files.",
                            recommendation: fullest.usagePercent >= 80 ? "Free space soon; keeping 10–20% available helps the system operate reliably." : "Available space is currently within a comfortable range.",
                            color: volumeUsageColor(percent: fullest.usagePercent)
                        )
                    }
                } else {
                    emptyState("No disk data available")
                }
            }
            .padding(12)
        }
        .background(TechColors.bgPrimary)
    }

    private func diskVolumeCard(volume: DiskVolumeInfo) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                ZStack {
                    Circle()
                        .fill(TechColors.accentTeal.opacity(0.15))
                        .frame(width: 26, height: 26)
                    Image(systemName: "internaldrive")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(TechColors.accentTeal)
                }
                Text(volume.name.isEmpty ? volume.mountPoint : volume.name)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(TechColors.textPrimary)
                    .lineLimit(1)
                Spacer()
                Text("\(ByteFormatter.format(volume.usedBytes)) / \(ByteFormatter.format(volume.totalBytes))")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(TechColors.textSecondary)
            }

            TechProgressBar(
                value: volume.usagePercent,
                color: volumeUsageColor(percent: volume.usagePercent),
                height: 6
            )

            HStack {
                Text("\(Int(volume.usagePercent))% used")
                    .font(.system(size: 9))
                    .foregroundColor(TechColors.textMuted)
                Spacer()
                Text("\(ByteFormatter.format(volume.totalBytes &- volume.usedBytes)) free")
                    .font(.system(size: 9))
                    .foregroundColor(TechColors.textMuted)
            }
        }
        .padding(12)
        .background(TechColors.bgCard)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(TechColors.borderSubtle, lineWidth: 1)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(volumeUsageColor(percent: volume.usagePercent).opacity(0.3), lineWidth: 1),
                    alignment: .top
                )
        )
    }

    private func volumeUsageColor(percent: Double) -> Color {
        if percent >= 90 { return TechColors.accentRed }
        if percent >= 75 { return TechColors.accentOrange }
        return TechColors.accentTeal
    }
}


// MARK: - 24小时历史图表

struct HistoryChartView24h: View {
    let monitorID: String
    let valueExtractor: (AnyMonitorSample) -> Double?
    let color: Color
    let historyStore: HistoryStore?
    var valueFormatter: ((Double) -> String)? = nil

    @State private var dataPoints: [ChartDataPoint] = []
    @State private var isLoading = true

    struct ChartDataPoint: Identifiable {
        let timestamp: Date
        let value: Double
        var id: Date { timestamp }

        static func aggregate(_ points: [ChartDataPoint], interval: TimeInterval = 30) -> [ChartDataPoint] {
            guard interval > 0 else { return points }

            let buckets = Dictionary(grouping: points) { point in
                floor(point.timestamp.timeIntervalSince1970 / interval)
            }
            return buckets.map { bucket, values in
                ChartDataPoint(
                    timestamp: Date(timeIntervalSince1970: bucket * interval),
                    value: values.reduce(0) { $0 + $1.value } / Double(values.count)
                )
            }
            .sorted { $0.timestamp < $1.timestamp }
        }
    }

    private var domainStart: Date {
        Calendar.current.date(byAdding: .hour, value: -24, to: Date()) ?? Date()
    }
    private var domainEnd: Date { Date() }

    private var xAxisValues: [Date] {
        let cal = Calendar.current
        return [-24, -20, -16, -12, -8, -4].compactMap { hour in
            cal.date(byAdding: .hour, value: hour, to: domainEnd)
        }
    }

    private var lastValueLabel: String {
        guard let v = dataPoints.last?.value else { return "—" }
        return valueFormatter?(v) ?? String(format: "%.1f", v)
    }

    var body: some View {
        ZStack {
            TechColors.bgCard
                .cornerRadius(8)

            if isLoading {
                ProgressView()
                    .tint(TechColors.accentCyan)
            } else if dataPoints.isEmpty {
                VStack(spacing: 4) {
                    Text("No history data")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(TechColors.textMuted)
                    Text("Data will appear as collected")
                        .font(.system(size: 9))
                        .foregroundColor(TechColors.textMuted.opacity(0.6))
                }
            } else {
                ZStack(alignment: .topTrailing) {
                    Chart(dataPoints) { point in
                        LineMark(
                            x: .value("Time", point.timestamp),
                            y: .value("Value", point.value)
                        )
                        .foregroundStyle(color)
                        .interpolationMethod(.catmullRom)

                        if point.id == dataPoints.last?.id {
                            PointMark(
                                x: .value("Time", point.timestamp),
                                y: .value("Value", point.value)
                            )
                            .foregroundStyle(color)
                            .symbolSize(40)
                        }
                    }
                    .chartXScale(domain: domainStart...domainEnd)
                    .chartXAxis {
                        AxisMarks(values: [domainStart] + xAxisValues + [domainEnd]) { value in
                            if let date = value.as(Date.self) {
                                let hoursAgo = abs(Int(date.timeIntervalSinceNow / 3600))
                                let label = hoursAgo == 0 ? "now" : "\(hoursAgo)h"
                                AxisValueLabel {
                                    Text(label)
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundColor(TechColors.textMuted)
                                }
                            }
                            AxisGridLine()
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading) { _ in
                            AxisGridLine()
                                .foregroundStyle(TechColors.borderSubtle)
                            AxisValueLabel()
                                .foregroundStyle(TechColors.textMuted)
                        }
                    }
                    .chartPlotStyle { plotArea in
                        plotArea
                            .background(TechColors.bgCard)
                    }

                    // 当前值叠加
                    VStack(alignment: .trailing, spacing: 1) {
                        Text("now")
                            .font(.system(size: 8))
                            .foregroundColor(TechColors.textMuted)
                        Text(lastValueLabel)
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(color)
                            .shadow(color: color.opacity(0.5), radius: 4)
                    }
                    .padding(6)
                    .background(TechColors.bgCard.opacity(0.85))
                    .cornerRadius(6)
                    .padding(6)
                }
            }
        }
        .frame(height: 100)
        .task(id: monitorID) {
            loadData()
        }
    }

    private func loadData() {
        guard let store = historyStore else {
            isLoading = false
            return
        }
        let now = Date()
        let since = Calendar.current.date(byAdding: .hour, value: -24, to: now)!
        Task {
            guard let samples = try? await store.query(monitorID: monitorID, from: since, to: now) else {
                await MainActor.run { isLoading = false }
                return
            }
            let rawPoints = samples.compactMap { sample -> ChartDataPoint? in
                guard let value = valueExtractor(sample) else { return nil }
                return ChartDataPoint(timestamp: sample.timestamp, value: value)
            }
            let points = ChartDataPoint.aggregate(rawPoints)
            await MainActor.run {
                self.dataPoints = points
                self.isLoading = false
            }
        }
    }
}

// MARK: - 通用 UI 组件

private func metricMainCard(title: String, icon: String, iconColor: Color, mainValue: String, mainColor: Color, extras: [(String, String)]) -> some View {
    VStack(spacing: 10) {
        HStack {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 30, height: 30)
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(iconColor)
            }
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(TechColors.textSecondary)
            Spacer()
            GlowLabel(mainValue, color: mainColor, size: 28)
        }
        .padding(.horizontal, 12)
        .padding(.top, 12)

        if !extras.isEmpty {
            HStack(spacing: 0) {
                ForEach(Array(extras.enumerated()), id: \.offset) { _, item in
                    VStack(spacing: 2) {
                        Text(item.1)
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(TechColors.textPrimary)
                        Text(item.0)
                            .font(.system(size: 9))
                            .foregroundColor(TechColors.textMuted)
                    }
                    .frame(maxWidth: .infinity)
                    if extras.count > 1 && item.0 != extras.last?.0 {
                        Spacer()
                    }
                }
            }
            .padding(.horizontal, 12)
        }

        Rectangle()
            .fill(iconColor.opacity(0.5))
            .frame(height: 1)
    }
    .background(TechColors.bgCard)
    .cornerRadius(8)
    .overlay(
        RoundedRectangle(cornerRadius: 8)
            .stroke(TechColors.borderSubtle, lineWidth: 1)
    )
}

private func chartCard(title: String, color: Color, @ViewBuilder content: () -> some View) -> some View {
    VStack(alignment: .leading, spacing: 6) {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
                .shadow(color: color.opacity(0.8), radius: 3)
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(TechColors.textSecondary)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)

        content()
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
    }
    .background(TechColors.bgCard)
    .cornerRadius(8)
    .overlay(
        RoundedRectangle(cornerRadius: 8)
            .stroke(TechColors.borderSubtle, lineWidth: 1)
    )
}

private func emptyState(_ message: String) -> some View {
    VStack {
        Spacer()
        Image(systemName: "exclamationmark.triangle")
            .font(.system(size: 24))
            .foregroundColor(TechColors.textMuted)
        Text(message)
            .font(.system(size: 12))
            .foregroundColor(TechColors.textMuted)
        Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
}
