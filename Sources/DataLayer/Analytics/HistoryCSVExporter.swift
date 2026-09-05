import Foundation
import MonitorEngine

public enum HistoryCSVExporter {
    public static func makeCSV(samplesByMonitor: [String: [AnyMonitorSample]]) -> String {
        var rows = ["timestamp,metric,value,unit,details"]
        for key in samplesByMonitor.keys.sorted() {
            for sample in samplesByMonitor[key, default: []].sorted(by: { $0.timestamp < $1.timestamp }) {
                rows.append(contentsOf: csvRows(for: sample))
            }
        }
        return rows.joined(separator: "\n") + "\n"
    }

    private static func csvRows(for sample: AnyMonitorSample) -> [String] {
        let timestamp = ISO8601DateFormatter().string(from: sample.timestamp)
        if let cpu = sample.cpu { return [row(timestamp, "CPU", cpu.usagePercent, "%", "user=\(cpu.userPercent); system=\(cpu.systemPercent)")] }
        if let memory = sample.memory { return [row(timestamp, "Memory", memory.usagePercent, "%", "pressure=\(memory.pressureLevel.rawValue); swap=\(memory.swapUsedBytes)")] }
        if let network = sample.network { return [row(timestamp, "Network upload", network.uploadBytesPerSec, "B/s", ""), row(timestamp, "Network download", network.downloadBytesPerSec, "B/s", "")] }
        if let disk = sample.disk { return disk.volumes.map { row(timestamp, "Disk", $0.usagePercent, "%", "volume=\($0.name); mount=\($0.mountPoint)") } }
        if let battery = sample.battery { return [row(timestamp, "Battery health", battery.healthPercent, "%", "charge=\(battery.chargePercent); cycles=\(battery.cycleCount); source=\(battery.powerSource)")] }
        if let thermal = sample.temperature { return [row(timestamp, "Thermal", Double(thermalRank(thermal.thermalState)), "state", thermal.thermalState.rawValue)] }
        return []
    }

    private static func row(_ timestamp: String, _ metric: String, _ value: Double, _ unit: String, _ details: String) -> String {
        [timestamp, metric, String(format: "%.2f", value), unit, details].map(escape).joined(separator: ",")
    }

    private static func escape(_ value: String) -> String {
        "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }

    private static func thermalRank(_ state: SystemThermalState) -> Int {
        switch state { case .nominal: return 0; case .fair: return 1; case .serious: return 2; case .critical: return 3 }
    }
}
