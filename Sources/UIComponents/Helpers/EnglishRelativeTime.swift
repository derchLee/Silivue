import Foundation
import DataLayer

enum EnglishRelativeTime {
    static func format(_ date: Date, relativeTo now: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = AppLocalization.currentLocale
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: now)
    }
}
