import XCTest
@testable import DataLayer

final class DisplayModeTests: XCTestCase {

    func testAllCases() {
        XCTAssertEqual(DisplayMode.allCases.count, 3)
    }

    func testDisplayNames() {
        XCTAssertEqual(DisplayMode.compact.displayName, "Compact")
        XCTAssertEqual(DisplayMode.icon.displayName, "Icon")
        XCTAssertEqual(DisplayMode.numeric.displayName, "Numeric")
    }

    func testRawValues() {
        XCTAssertEqual(DisplayMode.compact.rawValue, "compact")
        XCTAssertEqual(DisplayMode.icon.rawValue, "icon")
        XCTAssertEqual(DisplayMode.numeric.rawValue, "numeric")
    }

    func testCodable() throws {
        let original = DisplayMode.numeric
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(DisplayMode.self, from: encoded)
        XCTAssertEqual(decoded, original)
    }
}
