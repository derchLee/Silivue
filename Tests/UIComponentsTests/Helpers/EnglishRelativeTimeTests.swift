import XCTest
@testable import UIComponents

final class EnglishRelativeTimeTests: XCTestCase {
    func testRelativeTimesUseEnglishUnits() {
        let now = Date(timeIntervalSince1970: 1_000_000)
        for (seconds, expected) in [(42.0, "seconds"), (1500.0, "minutes"), (7200.0, "hours")] {
            let text = EnglishRelativeTime.format(now.addingTimeInterval(-seconds), relativeTo: now)
            XCTAssertTrue(text.contains(expected), text)
            XCTAssertTrue(text.contains("ago"), text)
        }
    }
}
