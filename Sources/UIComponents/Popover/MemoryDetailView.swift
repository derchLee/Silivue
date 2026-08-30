import SwiftUI
import Charts
import MonitorEngine
import DataLayer

public struct MemoryDetailView: View {
    let sample: MemorySample
    let history: [Double]

    public init(sample: MemorySample, history: [Double] = []) {
        self.sample = sample
        self.history = history
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Memory")
                    .font(MetricFonts.panelTitle)
                    .foregroundColor(MetricColors.memory)
                Spacer()
                Text("\(Int(sample.usagePercent))%")
                    .font(MetricFonts.panelValue)
                    .foregroundColor(MetricColors.memory)
            }

            if !history.isEmpty {
                RealtimeChartView(data: history, color: MetricColors.memory, label: "Memory %", fixedYDomain: 0...100)
            }

            HStack(spacing: 12) {
                Text("\(ByteFormatter.format(sample.usedBytes)) / \(ByteFormatter.format(sample.totalBytes))")
                    .font(MetricFonts.panelDetail)
                    .foregroundColor(.secondary)

                Text(pressureText)
                    .font(MetricFonts.panelDetail)
                    .foregroundColor(pressureColor)
            }

            if sample.swapUsedBytes > 0 {
                Text("Swap: \(ByteFormatter.format(sample.swapUsedBytes))")
                    .font(MetricFonts.panelDetail)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var pressureText: String {
        switch sample.pressureLevel {
        case .normal: return "Normal"
        case .warning: return "Warning"
        case .critical: return "Critical"
        }
    }

    private var pressureColor: Color {
        switch sample.pressureLevel {
        case .normal: return .green
        case .warning: return MetricColors.warning
        case .critical: return MetricColors.danger
        }
    }
}
