import SwiftUI

/// 紧凑模式：进度条 + 百分比
public struct CompactMetricView: View {
    let label: String
    let value: Double
    let color: Color

    public init(label: String, value: Double, color: Color) {
        self.label = label
        self.value = value
        self.color = color
    }

    public var body: some View {
        HStack(spacing: 2) {
            Text(label)
                .font(MetricFonts.menuBar)
            ProgressView(value: value, total: 100)
                .progressViewStyle(.linear)
                .tint(color)
                .frame(width: 30)
            Text("\(Int(value))%")
                .font(MetricFonts.menuBarNumber)
                .foregroundColor(color)
        }
    }
}
