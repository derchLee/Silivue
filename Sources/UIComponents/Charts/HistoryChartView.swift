import SwiftUI
import Charts
import MonitorEngine
import DataLayer

public struct HistoryChartView: View {
    let monitorID: String
    let valueExtractor: (AnyMonitorSample) -> Double?
    let color: Color
    let label: String
    let historyStore: HistoryStore?

    @State private var dataPoints: [HistoryDataPoint] = []

    public struct HistoryDataPoint: Identifiable {
        public let id = UUID()
        public let timestamp: Date
        public let value: Double
    }

    public init(monitorID: String, valueExtractor: @escaping (AnyMonitorSample) -> Double?, color: Color, label: String, historyStore: HistoryStore? = nil) {
        self.monitorID = monitorID
        self.valueExtractor = valueExtractor
        self.color = color
        self.label = label
        self.historyStore = historyStore
    }

    public var body: some View {
        if #available(macOS 13.0, *) {
            if !dataPoints.isEmpty {
                Chart(dataPoints) { point in
                    LineMark(
                        x: .value("Time", point.timestamp),
                        y: .value(label, point.value)
                    )
                    .foregroundStyle(color)
                    .interpolationMethod(.catmullRom)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .hour, count: 6)) {
                        AxisValueLabel(format: .dateTime.hour())
                    }
                }
                .frame(height: 80)
            }
        }
    }

    public func loadData() async {
        guard let store = historyStore else { return }
        let now = Date()
        let yesterday = Calendar.current.date(byAdding: .hour, value: -24, to: now)!
        guard let samples = try? await store.query(monitorID: monitorID, from: yesterday, to: now) else { return }
        dataPoints = samples.compactMap { sample in
            guard let value = valueExtractor(sample) else { return nil }
            return HistoryDataPoint(timestamp: sample.timestamp, value: value)
        }
    }
}
