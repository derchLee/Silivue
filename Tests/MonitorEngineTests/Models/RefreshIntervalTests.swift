import XCTest
@testable import MonitorEngine

final class RefreshIntervalTests: XCTestCase {

    func testAllCases() {
        XCTAssertEqual(RefreshInterval.allCases.count, 4)
    }

    func testTimeIntervalValues() {
        XCTAssertEqual(RefreshInterval.twoSeconds.timeInterval, 2.0)
        XCTAssertEqual(RefreshInterval.fiveSeconds.timeInterval, 5.0)
        XCTAssertEqual(RefreshInterval.tenSeconds.timeInterval, 10.0)
        XCTAssertEqual(RefreshInterval.thirtySeconds.timeInterval, 30.0)
    }

    func testDisplayNames() {
        XCTAssertEqual(RefreshInterval.twoSeconds.displayName, "2s")
        XCTAssertEqual(RefreshInterval.fiveSeconds.displayName, "5s")
        XCTAssertEqual(RefreshInterval.tenSeconds.displayName, "10s")
        XCTAssertEqual(RefreshInterval.thirtySeconds.displayName, "30s")
    }

    func testRawValues() {
        XCTAssertEqual(RefreshInterval.twoSeconds.rawValue, 2.0)
        XCTAssertEqual(RefreshInterval.fiveSeconds.rawValue, 5.0)
        XCTAssertEqual(RefreshInterval.tenSeconds.rawValue, 10.0)
        XCTAssertEqual(RefreshInterval.thirtySeconds.rawValue, 30.0)
    }

    func testCodable() throws {
        let original = RefreshInterval.twoSeconds
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(RefreshInterval.self, from: encoded)
        XCTAssertEqual(decoded, original)
    }
}
