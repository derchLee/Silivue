import XCTest
import Combine
@testable import DataLayer
import MonitorEngine

final class UserDefaultsStoreTests: XCTestCase {

    private var store: UserDefaultsStore!
    private var testDefaults: UserDefaults!
    private var cancellables = Set<AnyCancellable>()

    override func setUp() {
        testDefaults = UserDefaults(suiteName: "SilivueTests-\(UUID().uuidString)")
        store = UserDefaultsStore(defaults: testDefaults)
    }

    override func tearDown() {
        cancellables.removeAll()
        testDefaults.removePersistentDomain(forName: testDefaults.dictionaryRepresentation()["SuiteName"] as? String ?? "")
        super.tearDown()
    }

    // MARK: - 默认值

    func testDefaultRefreshInterval() {
        XCTAssertEqual(store.refreshInterval, .twoSeconds)
    }

    func testDefaultDisplayMode() {
        XCTAssertEqual(store.displayMode, .compact)
    }

    func testDefaultEnabledMonitors() {
        XCTAssertEqual(store.enabledMonitors, ["cpu", "memory", "network", "disk", "battery", "temperature", "process"])
    }

    func testDefaultLaunchAtLogin() {
        XCTAssertFalse(store.launchAtLogin)
    }

    // MARK: - 持久化

    func testSavesRefreshInterval() {
        store.refreshInterval = .fiveSeconds
        let newStore = UserDefaultsStore(defaults: testDefaults)
        XCTAssertEqual(newStore.refreshInterval, .fiveSeconds)
    }

    func testSavesDisplayMode() {
        store.displayMode = .numeric
        let newStore = UserDefaultsStore(defaults: testDefaults)
        XCTAssertEqual(newStore.displayMode, .numeric)
    }

    func testSavesEnabledMonitors() {
        store.enabledMonitors = ["cpu", "disk"]
        let newStore = UserDefaultsStore(defaults: testDefaults)
        XCTAssertEqual(newStore.enabledMonitors, ["cpu", "disk"])
    }

    func testSavesLaunchAtLogin() {
        store.launchAtLogin = true
        let newStore = UserDefaultsStore(defaults: testDefaults)
        XCTAssertTrue(newStore.launchAtLogin)
    }

    // MARK: - 发布者

    func testSettingsChangedPublishes() {
        var receivedSettings: [AppSettings] = []
        store.settingsChanged.sink { receivedSettings.append($0) }.store(in: &cancellables)

        store.refreshInterval = .tenSeconds

        // 至少收到一次变更
        XCTAssertTrue(receivedSettings.count >= 1)
        XCTAssertEqual(receivedSettings.last?.refreshInterval, .tenSeconds)
    }
}
