import SwiftUI
import MonitorEngine

public struct BatteryDetailView: View {
    let sample: BatterySample

    public init(sample: BatterySample) {
        self.sample = sample
    }

    public var body: some View {
        VStack(spacing: 8) {
            HStack {
                ZStack {
                    Circle()
                        .fill(TechColors.accentGreen.opacity(0.15))
                        .frame(width: 26, height: 26)
                    Image(systemName: sample.isCharging ? "bolt.fill" : "battery.100")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(batteryAccentColor)
                }
                Text("Battery")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(TechColors.textSecondary)
                Spacer()
                GlowLabel("\(Int(sample.chargePercent))%", color: batteryAccentColor, size: 18)
            }

            TechProgressBar(value: sample.chargePercent, color: batteryAccentColor, height: 5)

            HStack(spacing: 0) {
                batteryChip("Power", sample.powerSource, sample.isCharging ? TechColors.accentYellow : TechColors.textSecondary)
                if sample.timeRemaining > 0 {
                    batteryChip("Remaining", "\(sample.timeRemaining)min", TechColors.accentCyan)
                }
                batteryChip("Health", "\(Int(sample.healthPercent))%", healthColor)
                batteryChip("Cycles", "\(sample.cycleCount)", TechColors.textMuted)
            }

            if !healthTip.isEmpty {
                HStack(spacing: 5) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 9))
                        .foregroundColor(TechColors.accentYellow)
                    Text(healthTip)
                        .font(.system(size: 9))
                        .foregroundColor(TechColors.textSecondary)
                }
                .padding(6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(TechColors.accentYellow.opacity(0.08))
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(TechColors.accentYellow.opacity(0.2), lineWidth: 1)
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
                        .stroke(batteryAccentColor.opacity(0.3), lineWidth: 1),
                    alignment: .top
                )
        )
    }

    private var batteryAccentColor: Color {
        if sample.chargePercent > 50 { return TechColors.accentGreen }
        if sample.chargePercent > 20 { return TechColors.accentOrange }
        return TechColors.accentRed
    }

    private var healthColor: Color {
        if sample.healthPercent >= 80 { return TechColors.accentGreen }
        if sample.healthPercent >= 60 { return TechColors.accentOrange }
        return TechColors.accentRed
    }

    private var healthTip: String {
        var tips: [String] = []
        if sample.cycleCount > 500 {
            tips.append("High cycle count")
        }
        if sample.healthPercent < 80 {
            tips.append("Health degraded")
        }
        if sample.isCharging && sample.chargePercent > 80 {
            tips.append("Unplug at 80% for longevity")
        }
        return tips.joined(separator: " · ")
    }

    private func batteryChip(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: 1) {
            Text(value)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 7))
                .foregroundColor(TechColors.textMuted)
        }
        .frame(maxWidth: .infinity)
    }
}