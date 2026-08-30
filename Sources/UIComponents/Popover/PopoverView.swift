import SwiftUI
import MonitorEngine
import DataLayer

// MARK: - 下拉详情面板（科技感设计）

public struct PopoverView: View {
    @ObservedObject var engine: MonitorEngine
    let settings: SettingsStore
    let historyStore: HistoryStore?
    let onSettingsTapped: () -> Void
    let onMoreTapped: () -> Void

    public init(engine: MonitorEngine, settings: SettingsStore, historyStore: HistoryStore? = nil, onSettingsTapped: @escaping () -> Void, onMoreTapped: @escaping () -> Void) {
        self.engine = engine
        self.settings = settings
        self.historyStore = historyStore
        self.onSettingsTapped = onSettingsTapped
        self.onMoreTapped = onMoreTapped
    }

    public var body: some View {
        ZStack {
            // 深色背景
            TechColors.bgPrimary
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                // 顶部标题栏
                popoverHeader

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 8) {
                        if let cpu = engine.latestCPU {
                            popoverCPUSection(cpu)
                        }
                        if let mem = engine.latestMemory {
                            popoverMemorySection(mem)
                        }
                        if let net = engine.latestNetwork {
                            popoverNetworkSection(net)
                        }
                        if let disk = engine.latestDisk {
                            popoverDiskSection(disk)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                }

                // 底部操作栏
                popoverFooter
            }
        }
        .frame(width: 320)
    }

    // MARK: - 顶部标题栏

    private var popoverHeader: some View {
        HStack(spacing: 8) {
            // Logo / 图标
            ZStack {
                Circle()
                    .fill(TechColors.accentCyan.opacity(0.15))
                    .frame(width: 28, height: 28)
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(TechColors.accentCyan)
            }
            .shadow(color: TechColors.accentCyan.opacity(0.4), radius: 4)

            VStack(alignment: .leading, spacing: 0) {
                Text("Silivue")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(TechColors.textPrimary)
                Text("System Monitor")
                    .font(.system(size: 9))
                    .foregroundColor(TechColors.textMuted)
            }

            Spacer()

            Button(action: onSettingsTapped) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 13))
                    .foregroundColor(TechColors.textSecondary)
            }
            .buttonStyle(.plain)
            .frame(width: 28, height: 28)
            .background(TechColors.bgHover)
            .cornerRadius(6)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(TechColors.bgSecondary)
        .overlay(
            Rectangle()
                .fill(TechColors.accentCyan.opacity(0.5))
                .frame(height: 1),
            alignment: .bottom
        )
    }

    // MARK: - CPU 区域

    private func popoverCPUSection(_ cpu: CPUSample) -> some View {
        VStack(spacing: 8) {
            // 卡片头部
            HStack {
                ZStack {
                    Circle()
                        .fill(TechColors.accentCyan.opacity(0.15))
                        .frame(width: 26, height: 26)
                    Image(systemName: "cpu")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(TechColors.accentCyan)
                }
                Text("CPU")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(TechColors.textSecondary)
                Spacer()
                GlowLabel("\(Int(cpu.usagePercent))%", color: TechColors.accentCyan, size: 18)
            }

            // 进度条
            TechProgressBar(value: cpu.usagePercent, color: TechColors.accentCyan, height: 5)

            // 详细信息
            HStack {
                cpuChip("User", "\(Int(cpu.userPercent))%")
                Spacer()
                cpuChip("System", "\(Int(cpu.systemPercent))%")
                Spacer()
                cpuChip("Idle", "\(Int(cpu.idlePercent))%")
                Spacer()
                cpuChip("Cores", "\(cpu.coreCount)")
            }
        }
        .padding(10)
        .background(TechColors.bgCard)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(TechColors.borderSubtle, lineWidth: 1)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            LinearGradient(
                                colors: [TechColors.accentCyan.opacity(0.3), TechColors.accentCyan.opacity(0)],
                                startPoint: .topLeading,
                                endPoint: .topTrailing
                            ),
                            lineWidth: 1
                        ),
                    alignment: .top
                )
        )
    }

    private func cpuChip(_ label: String, _ value: String) -> some View {
        VStack(spacing: 1) {
            Text(value)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundColor(TechColors.textPrimary)
            Text(label)
                .font(.system(size: 8))
                .foregroundColor(TechColors.textMuted)
        }
    }

    private func memChip(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: 1) {
            Text(value)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 7))
                .foregroundColor(TechColors.textMuted)
        }
    }

    private func memoryColor(for percent: Double) -> Color {
        if percent >= 90 { return TechColors.accentRed }
        if percent >= 75 { return TechColors.accentOrange }
        return TechColors.accentPurple
    }

    // MARK: - 内存区域

    private func popoverMemorySection(_ mem: MemorySample) -> some View {
        VStack(spacing: 8) {
            HStack {
                ZStack {
                    Circle()
                        .fill(TechColors.accentPurple.opacity(0.15))
                        .frame(width: 26, height: 26)
                    Image(systemName: "memorychip")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(TechColors.accentPurple)
                }
                Text("Memory")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(TechColors.textSecondary)
                Spacer()
                GlowLabel("\(Int(mem.usagePercent))%", color: memoryColor(for: mem.usagePercent), size: 18)
            }

            TechProgressBar(value: mem.usagePercent, color: memoryColor(for: mem.usagePercent), height: 5)

            HStack(spacing: 8) {
                memChip("Used", ByteFormatter.format(mem.usedBytes), TechColors.accentPurple)
                memChip("Compressed", ByteFormatter.format(mem.compressedBytes), TechColors.accentBlue)
                memChip("Swap", ByteFormatter.format(mem.swapUsedBytes), mem.swapUsedBytes > 0 ? TechColors.accentOrange : TechColors.textMuted)
                memChip("Total", ByteFormatter.format(mem.totalBytes), TechColors.textSecondary)
            }
        }
        .padding(10)
        .background(TechColors.bgCard)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(TechColors.borderSubtle, lineWidth: 1)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            LinearGradient(
                                colors: [TechColors.accentPurple.opacity(0.3), TechColors.accentPurple.opacity(0)],
                                startPoint: .topLeading,
                                endPoint: .topTrailing
                            ),
                            lineWidth: 1
                        ),
                    alignment: .top
                )
        )
    }

    // MARK: - 网络区域

    private func popoverNetworkSection(_ net: NetworkSample) -> some View {
        VStack(spacing: 8) {
            HStack {
                ZStack {
                    Circle()
                        .fill(TechColors.accentGreen.opacity(0.15))
                        .frame(width: 26, height: 26)
                    Image(systemName: "network")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(TechColors.accentGreen)
                }
                Text("Network")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(TechColors.textSecondary)
                Spacer()
            }

            HStack(spacing: 16) {
                // 上传
                VStack(spacing: 3) {
                    HStack(spacing: 3) {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(TechColors.accentGreen)
                        Text("Upload")
                            .font(.system(size: 8))
                            .foregroundColor(TechColors.textMuted)
                    }
                    GlowLabel(ByteFormatter.formatSpeed(net.uploadBytesPerSec), color: TechColors.accentGreen, size: 12)
                }

                // 下载
                VStack(spacing: 3) {
                    HStack(spacing: 3) {
                        Image(systemName: "arrow.down")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(TechColors.accentBlue)
                        Text("Download")
                            .font(.system(size: 8))
                            .foregroundColor(TechColors.textMuted)
                    }
                    GlowLabel(ByteFormatter.formatSpeed(net.downloadBytesPerSec), color: TechColors.accentBlue, size: 12)
                }

                Spacer()
            }

            // Wi-Fi 信息
            if let ssid = net.ssid {
                HStack(spacing: 4) {
                    Image(systemName: "wifi")
                        .font(.system(size: 9))
                        .foregroundColor(TechColors.textMuted)
                    Text(ssid)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(TechColors.textSecondary)
                    if let ip = net.localIP {
                        Text("·")
                            .foregroundColor(TechColors.textMuted)
                        Text(ip)
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(TechColors.textMuted)
                    }
                }
            }
        }
        .padding(10)
        .background(TechColors.bgCard)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(TechColors.borderSubtle, lineWidth: 1)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            LinearGradient(
                                colors: [TechColors.accentGreen.opacity(0.3), TechColors.accentGreen.opacity(0)],
                                startPoint: .topLeading,
                                endPoint: .topTrailing
                            ),
                            lineWidth: 1
                        ),
                    alignment: .top
                )
        )
    }

    // MARK: - 磁盘区域

    private func popoverDiskSection(_ disk: DiskSample) -> some View {
        VStack(spacing: 8) {
            HStack {
                ZStack {
                    Circle()
                        .fill(TechColors.accentTeal.opacity(0.15))
                        .frame(width: 26, height: 26)
                    Image(systemName: "internaldrive")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(TechColors.accentTeal)
                }
                Text("Disk")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(TechColors.textSecondary)
                Spacer()
            }

            ForEach(disk.volumes, id: \.mountPoint) { volume in
                VStack(spacing: 4) {
                    HStack {
                        Text(volume.name.isEmpty ? volume.mountPoint : volume.name)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(TechColors.textPrimary)
                            .lineLimit(1)
                        Spacer()
                        Text("\(ByteFormatter.format(volume.usedBytes)) / \(ByteFormatter.format(volume.totalBytes))")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(TechColors.textSecondary)
                    }

                    TechProgressBar(value: volume.usagePercent, color: TechColors.accentTeal, height: 4)

                    HStack {
                        Text("\(Int(volume.usagePercent))% used")
                            .font(.system(size: 8))
                            .foregroundColor(TechColors.textMuted)
                        Spacer()
                        Text("\(ByteFormatter.format(volume.totalBytes &- volume.usedBytes)) free")
                            .font(.system(size: 8))
                            .foregroundColor(TechColors.textMuted)
                    }
                }
            }
        }
        .padding(10)
        .background(TechColors.bgCard)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(TechColors.borderSubtle, lineWidth: 1)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            LinearGradient(
                                colors: [TechColors.accentTeal.opacity(0.3), TechColors.accentTeal.opacity(0)],
                                startPoint: .topLeading,
                                endPoint: .topTrailing
                            ),
                            lineWidth: 1
                        ),
                    alignment: .top
                )
        )
    }

    // MARK: - 底部操作栏

    private var popoverFooter: some View {
        HStack(spacing: 8) {
            // More 按钮
            Button(action: onMoreTapped) {
                HStack(spacing: 5) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 10, weight: .semibold))
                    Text("More...")
                        .font(.system(size: 10, weight: .semibold))
                }
                .foregroundColor(TechColors.accentCyan)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(TechColors.accentCyan.opacity(0.1))
                .cornerRadius(5)
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(TechColors.accentCyan.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            Spacer()

            // 刷新时间
            Text("Auto-refresh")
                .font(.system(size: 8))
                .foregroundColor(TechColors.textMuted)
            Circle()
                .fill(TechColors.accentGreen)
                .frame(width: 5, height: 5)
                .shadow(color: TechColors.accentGreen.opacity(0.8), radius: 3)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(TechColors.bgSecondary)
        .overlay(
            Rectangle()
                .fill(TechColors.borderSubtle)
                .frame(height: 1),
            alignment: .top
        )
    }
}
