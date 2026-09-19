import Foundation

public enum DisplayMode: String, CaseIterable, Codable {
    case compact
    case icon
    case numeric
    case quiet

    public var displayName: String {
        switch self {
        case .compact: return AppLocalization.text("Compact")
        case .icon: return AppLocalization.text("Icon")
        case .numeric: return AppLocalization.text("Numeric")
        case .quiet: return AppLocalization.text("Quiet")
        }
    }
}
