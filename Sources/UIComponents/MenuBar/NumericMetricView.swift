import SwiftUI

/// 数字模式：仅文本
public struct NumericMetricView: View {
    let label: String
    let value: String
    let color: Color

    public init(label: String, value: String, color: Color) {
        self.label = label
        self.value = value
        self.color = color
    }

    public var body: some View {
        HStack(spacing: 1) {
            Text("\(label):")
                .font(MetricFonts.menuBar)
            Text(value)
                .font(MetricFonts.menuBarNumber)
                .foregroundColor(color)
        }
    }
}
