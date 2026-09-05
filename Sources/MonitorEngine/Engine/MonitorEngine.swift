import Combine
import Foundation

public protocol SamplePersistence {
    func insertBatch(_ samples: [AnyMonitorSample]) async throws
}

public final class MonitorEngine: ObservableObject {
    @Published public private(set) var latestCPU: CPUSample?
    @Published public private(set) var latestMemory: MemorySample?
    @Published public private(set) var latestNetwork: NetworkSample?
    @Published public private(set) var latestDisk: DiskSample?
    @Published public private(set) var latestBattery: BatterySample?
    @Published public private(set) var latestTemperature: TemperatureSample?

    @Published public private(set) var cpuHistory: [Double] = []
    @Published public private(set) var memoryHistory: [Double] = []
    @Published public private(set) var networkUploadHistory: [Double] = []
    @Published public private(set) var networkDownloadHistory: [Double] = []
    @Published public private(set) var batteryHistory: [Double] = []
    @Published public private(set) var temperatureHistory: [Double] = []

    @Published public private(set) var dailyUploadBytes: UInt64 = 0
    @Published public private(set) var dailyDownloadBytes: UInt64 = 0

    private var midnightUploadTotal: UInt64 = 0
    private var midnightDownloadTotal: UInt64 = 0
    private var dailyResetDate: Date = Calendar.current.startOfDay(for: Date())

    private let midnightUploadKey = "dailyMidnightUpload"
    private let midnightDownloadKey = "dailyMidnightDownload"
    private let dailyResetDateKey = "dailyResetDate"

    public static let historyCapacity = 60

    private var monitors: [String: SystemMonitor] = [:]
    private var cancellables = Set<AnyCancellable>()
    private var historyStore: SamplePersistence?
    private var historyBuffer: [AnyMonitorSample] = []
    private static let historyFlushInterval = 10

    public init() {}

    public func register(_ monitor: SystemMonitor) {
        monitors[monitor.monitorID] = monitor
        monitor.currentSample
            .receive(on: DispatchQueue.main)
            .sink { [weak self] sample in
                self?.update(sample)
            }
            .store(in: &cancellables)
    }

    public func hasMonitor(with id: String) -> Bool {
        monitors[id] != nil
    }

    public func setHistoryStore(_ store: SamplePersistence?) {
        self.historyStore = store
    }

    public func startAll(interval: RefreshInterval, enabledMonitors: Set<String>) {
        for monitor in monitors.values {
            if enabledMonitors.contains(monitor.monitorID) {
                monitor.start(interval: interval)
            }
        }
    }

    public func stopAll() {
        for monitor in monitors.values {
            monitor.stop()
        }
    }

    public func clearHistory() {
        cpuHistory = []
        memoryHistory = []
        networkUploadHistory = []
        networkDownloadHistory = []
        batteryHistory = []
        temperatureHistory = []
    }

    private func update(_ sample: AnyMonitorSample) {
        if let cpu = sample.cpu {
            latestCPU = cpu
            appendHistory(&cpuHistory, value: cpu.usagePercent)
        }
        if let mem = sample.memory {
            latestMemory = mem
            appendHistory(&memoryHistory, value: mem.usagePercent)
        }
        if let net = sample.network {
            latestNetwork = net
            appendHistory(&networkUploadHistory, value: net.uploadBytesPerSec / 1024)
            appendHistory(&networkDownloadHistory, value: net.downloadBytesPerSec / 1024)
            updateDailyNetworkStats(net)
        }
        if sample.disk != nil { latestDisk = sample.disk }
        if let bat = sample.battery {
            latestBattery = bat
            appendHistory(&batteryHistory, value: bat.chargePercent)
        }
        if let temp = sample.temperature {
            latestTemperature = temp
            if let cpuTemp = temp.cpuTemperature {
                appendHistory(&temperatureHistory, value: cpuTemp)
            }
        }
        if historyStore != nil {
            historyBuffer.append(sample)
            if historyBuffer.count >= Self.historyFlushInterval {
                flushHistoryBuffer()
            }
        }
    }

    private func appendHistory(_ history: inout [Double], value: Double) {
        history.append(value)
        if history.count > Self.historyCapacity {
            history.removeFirst(history.count - Self.historyCapacity)
        }
    }

    private func updateDailyNetworkStats(_ net: NetworkSample) {
        let today = Calendar.current.startOfDay(for: Date())

        // 跨天重置：基准点持久化到 UserDefaults（App 重启后也有效）
        if today != dailyResetDate {
            midnightUploadTotal = UserDefaults.standard.object(forKey: midnightUploadKey) as? UInt64 ?? net.totalUploadBytes
            midnightDownloadTotal = UserDefaults.standard.object(forKey: midnightDownloadKey) as? UInt64 ?? net.totalDownloadBytes
            dailyResetDate = today
            // 新的一天，记录新的基准点
            UserDefaults.standard.set(net.totalUploadBytes, forKey: midnightUploadKey)
            UserDefaults.standard.set(net.totalDownloadBytes, forKey: midnightDownloadKey)
        } else {
            // 同一天 App 重启：从已保存的基准恢复
            if midnightUploadTotal == 0 {
                midnightUploadTotal = UserDefaults.standard.object(forKey: midnightUploadKey) as? UInt64 ?? net.totalUploadBytes
                midnightDownloadTotal = UserDefaults.standard.object(forKey: midnightDownloadKey) as? UInt64 ?? net.totalDownloadBytes
            }
        }

        // 每日流量 = 系统累计 - 基准点
        dailyUploadBytes = net.totalUploadBytes > midnightUploadTotal ? net.totalUploadBytes - midnightUploadTotal : 0
        dailyDownloadBytes = net.totalDownloadBytes > midnightDownloadTotal ? net.totalDownloadBytes - midnightDownloadTotal : 0
    }

    private func flushHistoryBuffer() {
        guard let store = historyStore, !historyBuffer.isEmpty else { return }
        let samples = historyBuffer
        historyBuffer = []
        Task {
            try? await store.insertBatch(samples)
        }
    }
}
