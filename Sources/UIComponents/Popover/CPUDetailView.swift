import SwiftUI
import Charts
import MonitorEngine
import DataLayer

public struct CPUDetailView: View {
    let sample: CPUSample
    let history: [Double]

    public init(sample: CPUSample, history: [Double] = []) {
        self.sample = sample
        self.history = history
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("CPU")
                    .font(MetricFonts.panelTitle)
                    .foregroundColor(MetricColors.cpu)
                Spacer()
                Text("\(Int(sample.usagePercent))%")
                    .font(MetricFonts.panelValue)
                    .foregroundColor(MetricColors.cpu)
            }

            if !history.isEmpty {
                RealtimeChartView(data: history, color: MetricColors.cpu, label: "CPU %", fixedYDomain: 0...100)
            }

            HStack(spacing: 12) {
                Label("\(sample.coreCount) cores", systemImage: "cpu")
                    .font(MetricFonts.panelDetail)
                    .foregroundColor(.secondary)
                if let freq = sample.frequencyGHz {
                    Label(String(format: "%.1f GHz", freq), systemImage: "gauge.with.dots.needle.33percent")
                        .font(MetricFonts.panelDetail)
                        .foregroundColor(.secondary)
                } else if let perf = sample.performanceCoreCount, let eff = sample.efficiencyCoreCount {
                    Label("\(perf)P + \(eff)E cores", systemImage: "cpu")
                        .font(MetricFonts.panelDetail)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}
