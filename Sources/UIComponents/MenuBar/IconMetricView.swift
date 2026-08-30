import SwiftUI

/// 图标模式：仅图标
public struct IconMetricView: View {
    let systemName: String
    let color: Color

    public init(systemName: String, color: Color) {
        self.systemName = systemName
        self.color = color
    }

    public var body: some View {
        Image(systemName: systemName)
            .font(MetricFonts.menuBar)
            .foregroundColor(color)
    }
}
