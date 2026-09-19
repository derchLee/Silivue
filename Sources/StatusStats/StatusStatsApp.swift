import AppKit
import SwiftUI
import DataLayer
import UIComponents

@main
struct SilivueApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Settings窗口（Command+, 打开）
        Settings {
            SettingsView(settings: appDelegate.settings)
        }
        .commands {
            LocalizedAppCommands(settings: appDelegate.settings)
        }
    }
}

private struct LocalizedAppCommands: Commands {
    @ObservedObject var settings: UserDefaultsStore

    var body: some Commands {
        CommandGroup(replacing: .appTermination) {
            Button(AppLocalization.text("Quit Silivue")) {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q")
        }
    }
}
