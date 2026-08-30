import Foundation

public enum RefreshInterval: Double, CaseIterable, Codable, Equatable {
    case twoSeconds = 2.0
    case fiveSeconds = 5.0
    case tenSeconds = 10.0
    case thirtySeconds = 30.0

    public var timeInterval: TimeInterval { rawValue }

    public var displayName: String {
        switch self {
        case .twoSeconds: return "2s"
        case .fiveSeconds: return "5s"
        case .tenSeconds: return "10s"
        case .thirtySeconds: return "30s"
        }
    }
}
