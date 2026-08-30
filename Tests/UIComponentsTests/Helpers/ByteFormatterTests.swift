import XCTest
@testable import UIComponents

final class ByteFormatterTests: XCTestCase {

    // MARK: - format

    func testFormatsZero() {
        XCTAssertEqual(ByteFormatter.format(0), "0 B")
    }

    func testFormatsBytes() {
        XCTAssertEqual(ByteFormatter.format(500), "500 B")
    }

    func testFormatsKilobytes() {
        XCTAssertEqual(ByteFormatter.format(1024), "1.00 KB")
    }

    func testFormatsMegabytes() {
        XCTAssertEqual(ByteFormatter.format(1_048_576), "1.00 MB")
    }

    func testFormatsGigabytes() {
        XCTAssertEqual(ByteFormatter.format(1_073_741_824), "1.00 GB")
    }

    func testFormatsTerabytes() {
        XCTAssertEqual(ByteFormatter.format(1_099_511_627_776), "1.00 TB")
    }

    func testFormatsLargeMegabytes() {
        let mb500: UInt64 = 500 * 1024 * 1024
        XCTAssertEqual(ByteFormatter.format(mb500), "500.00 MB")
    }

    // MARK: - formatSpeed

    func testFormatsSpeedZero() {
        XCTAssertEqual(ByteFormatter.formatSpeed(0), "0 B/s")
    }

    func testFormatsSpeedKB() {
        XCTAssertEqual(ByteFormatter.formatSpeed(1024), "1.00 KB/s")
    }

    func testFormatsSpeedMB() {
        let speed = 1.5 * 1024 * 1024  // 1.5 MB/s
        XCTAssertEqual(ByteFormatter.formatSpeed(speed), "1.50 MB/s")
    }
}