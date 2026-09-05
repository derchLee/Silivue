import SwiftUI
import UIComponents

@main
struct SilivueApp: App {
    init() {
        // Apply to this process only, including AppKit's standard menus/panels.
        var arguments = UserDefaults.standard.volatileDomain(forName: UserDefaults.argumentDomain)
        arguments["AppleLanguages"] = ["en"]
        UserDefaults.standard.setVolatileDomain(arguments, forName: UserDefaults.argumentDomain)
    }

    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Settings窗口（Command+, 打开）
        Settings {
            SettingsView(settings: appDelegate.settings)
        }
    }
}
