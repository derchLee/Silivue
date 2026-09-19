import Foundation

public enum AppLanguage: String, CaseIterable, Codable, Equatable, Identifiable {
    case english = "en"
    case korean = "ko"
    case german = "de"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .english: return "English"
        case .korean: return "한국어"
        case .german: return "Deutsch"
        }
    }

    public var localeIdentifier: String { rawValue }
}

/// Resolves strings from the executable's App Store localization bundle.
public enum AppLocalization {
    private static var language: AppLanguage = .english

    public static func configure(language: AppLanguage) {
        self.language = language
    }

    public static var currentLocale: Locale {
        Locale(identifier: language.localeIdentifier)
    }

    public static func text(_ key: String) -> String {
        let bundle = Bundle.main.path(forResource: language.rawValue, ofType: "lproj")
            .flatMap(Bundle.init(path:)) ?? .main
        return NSLocalizedString(key, bundle: bundle, value: key, comment: "")
    }

    /// Formats a localized template using the user's current language conventions.
    public static func format(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: text(key), locale: currentLocale, arguments: arguments)
    }
}
