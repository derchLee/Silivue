import XCTest
@testable import DataLayer
import MonitorEngine

final class AppSettingsTests: XCTestCase {

    func testDefaultValues() {
        let settings = AppSettings()
        XCTAssertEqual(settings.refreshInterval, .twoSeconds)
        XCTAssertEqual(settings.displayMode, .compact)
        XCTAssertEqual(settings.enabledMonitors, ["cpu", "memory", "network", "disk", "battery", "temperature"])
        XCTAssertFalse(settings.launchAtLogin)
    }

    func testEquatable() {
        let s1 = AppSettings()
        let s2 = AppSettings()
        XCTAssertEqual(s1, s2)
    }

    func testDifferentSettings() {
        let s1 = AppSettings()
        let s2 = AppSettings(refreshInterval: .thirtySeconds)
        XCTAssertNotEqual(s1, s2)
    }

    func testCustomInit() {
        let settings = AppSettings(refreshInterval: .fiveSeconds,
                                    displayMode: .numeric,
                                    enabledMonitors: ["cpu"],
                                    launchAtLogin: true)
        XCTAssertEqual(settings.refreshInterval, .fiveSeconds)
        XCTAssertEqual(settings.displayMode, .numeric)
        XCTAssertEqual(settings.enabledMonitors, ["cpu"])
        XCTAssertTrue(settings.launchAtLogin)
    }
}
