import SwiftUI
import MonitorEngine
import DataLayer

/// 菜单栏主视图，根据DisplayMode切换显示方式
public struct MenuBarView: View {
    let cpuSample: CPUSample?
    let memorySample: MemorySample?
    let networkSample: NetworkSample?
    let displayMode: DisplayMode
    let enabledMonitors: Set<String>

    public init(cpuSample: CPUSample?, memorySample: MemorySample?,
                networkSample: NetworkSample?, displayMode: DisplayMode,
                enabledMonitors: Set<String>) {
        self.cpuSample = cpuSample
        self.memorySample = memorySample
        self.networkSample = networkSample
        self.displayMode = displayMode
        self.enabledMonitors = enabledMonitors
    }

    public var body: some View {
        HStack(spacing: 6) {
            if enabledMonitors.contains("cpu"), let cpu = cpuSample {
                metricView(label: "CPU", value: cpu.usagePercent,
                           numericValue: "\(Int(cpu.usagePercent))%",
                           icon: "cpu", color: MetricColors.cpu)
            }
            if enabledMonitors.contains("memory"), let mem = memorySample {
                metricView(label: "RAM", value: mem.usagePercent,
                           numericValue: ByteFormatter.format(mem.usedBytes),
                           icon: "memorychip", color: MetricColors.memory)
            }
            if enabledMonitors.contains("network"), let net = networkSample {
                networkView(net: net)
            }
        }
    }

    @ViewBuilder
    private func metricView(label: String, value: Double, numericValue: String,
                             icon: String, color: Color) -> some View {
        switch displayMode {
        case .compact:
            CompactMetricView(label: label, value: value, color: color)
        case .icon:
            IconMetricView(systemName: icon, color: color)
        case .numeric:
            NumericMetricView(label: label, value: numericValue, color: color)
        }
    }

    @ViewBuilder
    private func networkView(net: NetworkSample) -> some View {
        switch displayMode {
        case .compact:
            HStack(spacing: 2) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 8))
                    .foregroundColor(MetricColors.networkUp)
                Text(ByteFormatter.formatSpeed(net.uploadBytesPerSec))
                    .font(MetricFonts.menuBar)
                Image(systemName: "arrow.down")
                    .font(.system(size: 8))
                    .foregroundColor(MetricColors.networkDown)
                Text(ByteFormatter.formatSpeed(net.downloadBytesPerSec))
                    .font(MetricFonts.menuBar)
            }
        case .icon:
            IconMetricView(systemName: "network", color: MetricColors.networkUp)
        case .numeric:
            HStack(spacing: 1) {
                Text("↑\(ByteFormatter.formatSpeed(net.uploadBytesPerSec))")
                    .font(MetricFonts.menuBar)
                    .foregroundColor(MetricColors.networkUp)
                Text("↓\(ByteFormatter.formatSpeed(net.downloadBytesPerSec))")
                    .font(MetricFonts.menuBar)
                    .foregroundColor(MetricColors.networkDown)
            }
        }
    }
}
