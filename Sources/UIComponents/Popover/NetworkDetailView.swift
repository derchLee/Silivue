import SwiftUI
import Charts
import MonitorEngine
import DataLayer

public struct NetworkDetailView: View {
    let sample: NetworkSample
    let uploadHistory: [Double]
    let downloadHistory: [Double]
    let dailyUploadBytes: UInt64
    let dailyDownloadBytes: UInt64

    public init(sample: NetworkSample, uploadHistory: [Double] = [], downloadHistory: [Double] = [], dailyUploadBytes: UInt64 = 0, dailyDownloadBytes: UInt64 = 0) {
        self.sample = sample
        self.uploadHistory = uploadHistory
        self.downloadHistory = downloadHistory
        self.dailyUploadBytes = dailyUploadBytes
        self.dailyDownloadBytes = dailyDownloadBytes
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Network")
                    .font(MetricFonts.panelTitle)
                    .foregroundColor(MetricColors.networkUp)
            }

            if let ssid = sample.ssid {
                HStack(spacing: 4) {
                    Image(systemName: "wifi")
                        .font(.system(size: 10))
                        .foregroundColor(MetricColors.networkUp)
                    Text(ssid)
                        .font(MetricFonts.panelDetail)
                        .foregroundColor(.secondary)
                }
            }
            if let ip = sample.localIP {
                HStack(spacing: 4) {
                    Image(systemName: "network")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    Text(ip)
                        .font(MetricFonts.panelDetail)
                        .foregroundColor(.secondary)
                }
            }

            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 10))
                        .foregroundColor(MetricColors.networkUp)
                    Text(ByteFormatter.formatSpeed(sample.uploadBytesPerSec))
                        .font(MetricFonts.panelDetail)
                }
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down")
                        .font(.system(size: 10))
                        .foregroundColor(MetricColors.networkDown)
                    Text(ByteFormatter.formatSpeed(sample.downloadBytesPerSec))
                        .font(MetricFonts.panelDetail)
                }
            }

            if !uploadHistory.isEmpty || !downloadHistory.isEmpty {
                NetworkChartView(uploadData: uploadHistory, downloadData: downloadHistory)
            }

            HStack(spacing: 12) {
                Text("Total ↑\(ByteFormatter.format(sample.totalUploadBytes))")
                    .font(MetricFonts.panelDetail)
                    .foregroundColor(.secondary)
                Text("↓\(ByteFormatter.format(sample.totalDownloadBytes))")
                    .font(MetricFonts.panelDetail)
                    .foregroundColor(.secondary)
            }

            if dailyUploadBytes > 0 || dailyDownloadBytes > 0 {
                HStack(spacing: 12) {
                    Text("Today ↑\(ByteFormatter.format(dailyUploadBytes))")
                        .font(MetricFonts.panelDetail)
                        .foregroundColor(.secondary)
                    Text("↓\(ByteFormatter.format(dailyDownloadBytes))")
                        .font(MetricFonts.panelDetail)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

// MARK: - 网络图表数据点

private struct NetworkDataPoint: Identifiable {
    let id = UUID()
    let index: Int
    let speed: Double
    let kind: String // "Upload" or "Download"
}

// MARK: - 网络双线图

private struct NetworkChartView: View {
    let uploadData: [Double]
    let downloadData: [Double]

    private var points: [NetworkDataPoint] {
        var result: [NetworkDataPoint] = []
        for (i, v) in uploadData.enumerated() {
            result.append(NetworkDataPoint(index: i, speed: v, kind: "Upload"))
        }
        for (i, v) in downloadData.enumerated() {
            result.append(NetworkDataPoint(index: i, speed: v, kind: "Download"))
        }
        return result
    }

    var body: some View {
        if #available(macOS 13.0, *) {
            Chart(points) { point in
                LineMark(
                    x: .value("Time", point.index),
                    y: .value("Speed", point.speed)
                )
                .foregroundStyle(by: .value("Type", point.kind))
                .interpolationMethod(.catmullRom)
            }
            .chartForegroundStyleScale([
                "Upload": MetricColors.networkUp,
                "Download": MetricColors.networkDown
            ])
            .chartYScale(domain: yDomain)
            .chartXAxis(.hidden)
            .chartLegend(.hidden)
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

    private var yDomain: ClosedRange<Double> {
        let upMax = uploadData.max() ?? 0
        let downMax = downloadData.max() ?? 0
        let maxVal = max(upMax, downMax)
        guard maxVal > 0 else { return 0...1 }
        return 0...(maxVal * 1.1)
    }

    private var yTickValues: [Double] {
        let domain = yDomain
        return [domain.lowerBound, (domain.lowerBound + domain.upperBound) / 2, domain.upperBound]
    }
}
