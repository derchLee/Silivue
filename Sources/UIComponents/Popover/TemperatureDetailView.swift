import SwiftUI
import MonitorEngine

public struct TemperatureDetailView: View {
    let sample: TemperatureSample

    public init(sample: TemperatureSample) {
        self.sample = sample
    }

    public var body: some View {
        VStack(spacing: 8) {
            HStack {
                ZStack {
                    Circle()
                        .fill(temperatureAccentColor.opacity(0.15))
                        .frame(width: 26, height: 26)
                    Image(systemName: sample.isOverheating ? "exclamationmark.triangle.fill" : "thermometer.medium")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(temperatureAccentColor)
                }
                Text("Temperature")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(TechColors.textSecondary)
                Spacer()
                if let cpu = sample.cpuTemperature {
                    GlowLabel("\(Int(cpu))°C", color: temperatureAccentColor, size: 18)
                }
            }

            // 过热警告
            if sample.isOverheating {
                HStack(spacing: 5) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 9))
                        .foregroundColor(TechColors.accentRed)
                    Text("High Temperature Warning")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(TechColors.accentRed)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(6)
                .background(TechColors.accentRed.opacity(0.1))
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(TechColors.accentRed.opacity(0.3), lineWidth: 1)
                )
            }

            // 温度详情
            HStack(spacing: 0) {
                if let cpu = sample.cpuTemperature {
                    tempChip("CPU", "\(Int(cpu))°C", TechColors.accentOrange)
                }
                if let gpu = sample.gpuTemperature {
                    tempChip("GPU", "\(Int(gpu))°C", TechColors.accentYellow)
                }
                if let _ = sample.cpuTemperature ?? sample.gpuTemperature {
                    tempChip("Status", sample.isOverheating ? "Hot" : "Normal", temperatureAccentColor)
                }
            }

            // 风扇转速
            if !sample.fanSpeeds.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Fan Speeds")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(TechColors.textMuted)

                    ForEach(sample.fanSpeeds, id: \.label) { fan in
                        HStack {
                            Text(fan.label)
                                .font(.system(size: 10))
                                .foregroundColor(TechColors.textPrimary)
                            Spacer()
                            Text("\(fan.currentRPM) RPM")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(TechColors.accentCyan)
                            if fan.maxRPM > 0 {
                                Text("\(Int(Double(fan.currentRPM) / Double(fan.maxRPM) * 100))%")
                                    .font(.system(size: 9))
                                    .foregroundColor(TechColors.textMuted)
                            }
                        }
                    }
                }
                .padding(8)
                .background(TechColors.bgCard)
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(TechColors.borderSubtle, lineWidth: 1)
                )
            }
        }
        .padding(10)
        .background(TechColors.bgCard)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(TechColors.borderSubtle, lineWidth: 1)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(temperatureAccentColor.opacity(0.3), lineWidth: 1),
                    alignment: .top
                )
        )
    }

    private var temperatureAccentColor: Color {
        if sample.isOverheating { return TechColors.accentRed }
        return TechColors.accentOrange
    }

    private func tempChip(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: 1) {
            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 8))
                .foregroundColor(TechColors.textMuted)
        }
        .frame(maxWidth: .infinity)
    }
}