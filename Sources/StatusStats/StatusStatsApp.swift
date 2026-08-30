import SwiftUI
import UIComponents

@main
struct SilivueApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Settings窗口（Command+, 打开）
        Settings {
            SettingsView(settings: appDelegate.settings)
        }
    }
}
