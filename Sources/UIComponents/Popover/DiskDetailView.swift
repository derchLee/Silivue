import SwiftUI
import MonitorEngine

public struct DiskDetailView: View {
    let sample: DiskSample

    public init(sample: DiskSample) {
        self.sample = sample
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Disk")
                .font(MetricFonts.panelTitle)
                .foregroundColor(MetricColors.disk)

            ForEach(sample.volumes, id: \.mountPoint) { volume in
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(volume.name)
                            .font(MetricFonts.panelDetail)
                            .foregroundColor(.primary)
                        Spacer()
                        Text("\(Int(volume.usagePercent))%")
                            .font(MetricFonts.panelValue)
                            .foregroundColor(volumeColor(volume.usagePercent))
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.secondary.opacity(0.2))
                                .frame(height: 4)
                            RoundedRectangle(cornerRadius: 2)
                                .fill(volumeColor(volume.usagePercent))
                                .frame(width: geo.size.width * min(CGFloat(volume.usagePercent / 100), 1.0), height: 4)
                        }
                    }
                    .frame(height: 4)

                    Text("\(ByteFormatter.format(volume.usedBytes)) / \(ByteFormatter.format(volume.totalBytes))")
                        .font(MetricFonts.panelDetail)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private func volumeColor(_ percent: Double) -> Color {
        if percent > 90 { return MetricColors.danger }
        if percent > 75 { return MetricColors.warning }
        return MetricColors.disk
    }
}
