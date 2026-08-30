import XCTest
@testable import MonitorEngine

final class RefreshIntervalTests: XCTestCase {

    func testAllCases() {
        XCTAssertEqual(RefreshInterval.allCases.count, 3)
    }

    func testTimeIntervalValues() {
        XCTAssertEqual(RefreshInterval.oneSecond.timeInterval, 1.0)
        XCTAssertEqual(RefreshInterval.twoSeconds.timeInterval, 2.0)
        XCTAssertEqual(RefreshInterval.fiveSeconds.timeInterval, 5.0)
    }

    func testDisplayNames() {
        XCTAssertEqual(RefreshInterval.oneSecond.displayName, "1s")
        XCTAssertEqual(RefreshInterval.twoSeconds.displayName, "2s")
        XCTAssertEqual(RefreshInterval.fiveSeconds.displayName, "5s")
    }

    func testRawValues() {
        XCTAssertEqual(RefreshInterval.oneSecond.rawValue, 1.0)
        XCTAssertEqual(RefreshInterval.twoSeconds.rawValue, 2.0)
        XCTAssertEqual(RefreshInterval.fiveSeconds.rawValue, 5.0)
    }

    func testCodable() throws {
        let original = RefreshInterval.twoSeconds
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(RefreshInterval.self, from: encoded)
        XCTAssertEqual(decoded, original)
    }
}
