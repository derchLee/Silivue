public enum DisplayMode: String, CaseIterable, Codable {
    case compact
    case icon
    case numeric

    public var displayName: String {
        switch self {
        case .compact: return "Compact"
        case .icon: return "Icon"
        case .numeric: return "Numeric"
        }
    }
}
