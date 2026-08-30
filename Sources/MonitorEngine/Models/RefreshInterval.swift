import Foundation

public enum RefreshInterval: Double, CaseIterable, Codable, Equatable {
    case oneSecond = 1.0
    case twoSeconds = 2.0
    case fiveSeconds = 5.0

    public var timeInterval: TimeInterval { rawValue }

    public var displayName: String {
        switch self {
        case .oneSecond: return "1s"
        case .twoSeconds: return "2s"
        case .fiveSeconds: return "5s"
        }
    }
}
