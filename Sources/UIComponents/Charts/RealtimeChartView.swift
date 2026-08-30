import SwiftUI
import Charts

/// 实时折线图（最近60个数据点）
public struct RealtimeChartView: View {
    let data: [Double]
    let color: Color
    let label: String
    let fixedYDomain: ClosedRange<Double>?

    /// 初始化图表
    /// - Parameters:
    ///   - data: 数据点数组
    ///   - color: 线条颜色
    ///   - label: Y轴标签
    ///   - fixedYDomain: 固定Y轴范围（如百分比用 0...100），nil 则自适应
    public init(data: [Double], color: Color, label: String, fixedYDomain: ClosedRange<Double>? = nil) {
        self.data = data
        self.color = color
        self.label = label
        self.fixedYDomain = fixedYDomain
    }

    public var body: some View {
        if #available(macOS 13.0, *) {
            Chart {
                ForEach(Array(data.enumerated()), id: \.offset) { index, value in
                    LineMark(
                        x: .value("Time", index),
                        y: .value(label, value)
                    )
                    .foregroundStyle(color)
                    .interpolationMethod(.catmullRom)
                }
            }
            .chartYScale(domain: effectiveYDomain)
            .chartXAxis(.hidden)
            .chartYAxis {
                AxisMarks(position: .leading, values: yTickValues) {
                    AxisValueLabel()
                        .font(.system(size: 9, design: .monospaced))
                }
            }
            .chartPlotStyle { plotArea in
                plotArea
                    .frame(height: 50)
            }
        }
    }

    private var effectiveYDomain: ClosedRange<Double> {
        if let fixed = fixedYDomain { return fixed }
        guard let maxVal = data.max(), maxVal > 0 else { return 0...1 }
        return 0...(maxVal * 1.1)
    }

    private var yTickValues: [Double] {
        if let fixed = fixedYDomain {
            return [fixed.lowerBound, (fixed.lowerBound + fixed.upperBound) / 2, fixed.upperBound]
        }
        let domain = effectiveYDomain
        return [domain.lowerBound, (domain.lowerBound + domain.upperBound) / 2, domain.upperBound]
    }
}
