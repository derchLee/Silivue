import SwiftUI

// MARK: - 科技感配色

struct TechColors {
    // 背景
    static let bgPrimary    = Color(hex: "0D0F1A")   // 深空黑
    static let bgSecondary  = Color(hex: "13162B")   // 深蓝灰
    static let bgCard       = Color(hex: "1A1F3A")   // 卡片背景
    static let bgHover     = Color(hex: "1F2544")   // hover 态

    // 边框
    static let borderSubtle = Color(hex: "2A3050")   // 细边框
    static let borderAccent = Color(hex: "3D4A7A")   // 强调边框

    // 文字
    static let textPrimary  = Color(hex: "E8ECF8")   // 主文字
    static let textSecondary = Color(hex: "8892B0")  // 次要文字
    static let textMuted    = Color(hex: "4A5580")   // 弱化文字

    // 强调色
    static let accentCyan    = Color(hex: "00E5FF")   // 青色
    static let accentPurple  = Color(hex: "A855F7")  // 紫色
    static let accentGreen   = Color(hex: "34D399")  // 绿色
    static let accentBlue    = Color(hex: "60A5FA")  // 蓝色
    static let accentRed     = Color(hex: "F87171")  // 红色
    static let accentOrange  = Color(hex: "FB923C")  // 橙色
    static let accentTeal    = Color(hex: "2DD4BF")  // 蓝绿
    static let accentYellow  = Color(hex: "FBBF24")  // 黄色

    // 渐变
    static let gradientCyan  = LinearGradient(colors: [Color(hex: "00E5FF"), Color(hex: "0078D4")], startPoint: .leading, endPoint: .trailing)
    static let gradientPurple = LinearGradient(colors: [Color(hex: "A855F7"), Color(hex: "6366F1")], startPoint: .leading, endPoint: .trailing)
    static let gradientDark   = LinearGradient(colors: [Color(hex: "13162B"), Color(hex: "0D0F1A")], startPoint: .top, endPoint: .bottom)

    // 发光
    static let glowCyan   = Color(hex: "00E5FF").opacity(0.3)
    static let glowPurple = Color(hex: "A855F7").opacity(0.3)
}

// MARK: - 颜色扩展

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b, a: UInt64
        switch hex.count {
        case 6:
            (r, g, b, a) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF, 255)
        case 8:
            (r, g, b, a) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b, a) = (0, 0, 0, 255)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - 科技感卡片

struct TechCard<Content: View>: View {
    let accentColor: Color
    let content: () -> Content

    init(accentColor: Color, @ViewBuilder content: @escaping () -> Content) {
        self.accentColor = accentColor
        self.content = content
    }

    var body: some View {
        content()
            .background(TechColors.bgCard)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(TechColors.borderSubtle, lineWidth: 1)
            )
            .cornerRadius(8)
    }
}

// MARK: - 指标行

struct MetricRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let subtitle: String?

    init(icon: String, iconColor: Color, title: String, value: String, subtitle: String? = nil) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.value = value
        self.subtitle = subtitle
    }

    var body: some View {
        HStack(spacing: 10) {
            // 图标
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 28, height: 28)
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(iconColor)
            }

            // 标题 + 数值
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(TechColors.textSecondary)
                Text(value)
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(TechColors.textPrimary)
            }

            Spacer()

            // 副标题
            if let sub = subtitle {
                Text(sub)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(TechColors.textMuted)
            }
        }
    }
}

// MARK: - 进度条

struct TechProgressBar: View {
    let value: Double
    let color: Color
    let height: CGFloat

    init(value: Double, color: Color, height: CGFloat = 4) {
        self.value = value
        self.color = color
        self.height = height
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // 背景
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(TechColors.borderSubtle)

                // 渐变填充
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.6)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(0, geo.size.width * min(value / 100, 1)))
                    .shadow(color: color.opacity(0.5), radius: 4, x: 0, y: 0)

                // 高亮点
                if value > 1 {
                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(Color.white.opacity(0.3))
                        .frame(width: geo.size.width * min(value / 100, 1))
                        .mask(
                            HStack(spacing: 0) {
                                Spacer()
                                Rectangle()
                                    .frame(width: geo.size.width * min(value / 100, 1) * 0.3)
                            }
                        )
                }
            }
        }
        .frame(height: height)
    }
}

// MARK: - Tab 按钮

struct TechTabButton: View {
    let title: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundColor(isSelected ? TechColors.bgPrimary : color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(color)
                            .shadow(color: color.opacity(0.4), radius: 4, x: 0, y: 0)
                    } else {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(color.opacity(0.15))
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isSelected ? color : color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 发光文字

struct GlowLabel: View {
    let text: String
    let color: Color
    let size: CGFloat

    init(_ text: String, color: Color, size: CGFloat = 12) {
        self.text = text
        self.color = color
        self.size = size
    }

    var body: some View {
        Text(text)
            .font(.system(size: size, weight: .bold, design: .monospaced))
            .foregroundColor(color)
            .shadow(color: color.opacity(0.8), radius: 6, x: 0, y: 0)
    }
}
