import XCTest
import MonitorEngine
@testable import DataLayer

final class SQLiteHistoryStoreTests: XCTestCase {
    private var store: SQLiteHistoryStore!

    override func setUp() async throws {
        try await super.setUp()
        // 使用内存数据库，每次测试隔离
        store = try SQLiteHistoryStore(inMemory: true)
    }

    override func tearDown() async throws {
        store = nil
        try await super.tearDown()
    }

    // MARK: - Insert & Query

    func testInsertAndQueryCPU() async throws {
        let sample = CPUSample(usagePercent: 45.0, userPercent: 30.0, systemPercent: 15.0,
                               idlePercent: 55.0, coreCount: 8)
        let anySample = AnyMonitorSample(sample)

        try await store.insert(anySample)

        let now = Date()
        let results = try await store.query(monitorID: "cpu", from: now.addingTimeInterval(-60), to: now.addingTimeInterval(60))
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.cpu?.usagePercent, 45.0)
    }

    func testInsertAndQueryMemory() async throws {
        let sample = MemorySample(usedBytes: 8_000_000_000, totalBytes: 16_000_000_000,
                                  usagePercent: 50.0, pressureLevel: .normal,
                                  swapUsedBytes: 0, compressedBytes: 100_000)
        try await store.insert(AnyMonitorSample(sample))

        let now = Date()
        let results = try await store.query(monitorID: "memory", from: now.addingTimeInterval(-60), to: now.addingTimeInterval(60))
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.memory?.usagePercent, 50.0)
    }

    func testInsertAndQueryNetwork() async throws {
        let sample = NetworkSample(uploadBytesPerSec: 1024.0, downloadBytesPerSec: 2048.0,
                                   totalUploadBytes: 10_000, totalDownloadBytes: 20_000)
        try await store.insert(AnyMonitorSample(sample))

        let now = Date()
        let results = try await store.query(monitorID: "network", from: now.addingTimeInterval(-60), to: now.addingTimeInterval(60))
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.network?.uploadBytesPerSec, 1024.0)
    }

    func testQueryReturnsEmptyForWrongMonitorID() async throws {
        let sample = CPUSample(usagePercent: 45.0, userPercent: 30.0, systemPercent: 15.0,
                               idlePercent: 55.0, coreCount: 8)
        try await store.insert(AnyMonitorSample(sample))

        let now = Date()
        let results = try await store.query(monitorID: "memory", from: now.addingTimeInterval(-60), to: now.addingTimeInterval(60))
        XCTAssertTrue(results.isEmpty)
    }

    // MARK: - Date Range

    func testQueryFiltersByDateRange() async throws {
        let oldDate = Date().addingTimeInterval(-3600) // 1小时前
        let recentDate = Date()

        let oldSample = CPUSample(timestamp: oldDate, usagePercent: 10.0, userPercent: 5.0,
                                  systemPercent: 5.0, idlePercent: 90.0, coreCount: 8)
        let recentSample = CPUSample(timestamp: recentDate, usagePercent: 50.0, userPercent: 30.0,
                                     systemPercent: 20.0, idlePercent: 50.0, coreCount: 8)

        try await store.insert(AnyMonitorSample(oldSample))
        try await store.insert(AnyMonitorSample(recentSample))

        // 只查询最近1分钟
        let results = try await store.query(monitorID: "cpu", from: recentDate.addingTimeInterval(-60), to: recentDate.addingTimeInterval(60))
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.cpu?.usagePercent, 50.0)
    }

    func testQuerySampledCapsDenseHistoryByTimeBuckets() async throws {
        let start = Date(timeIntervalSince1970: 10_020)
        let samples = (0..<120).map { index in
            AnyMonitorSample(CPUSample(timestamp: start.addingTimeInterval(Double(index)),
                                       usagePercent: Double(index), userPercent: 0,
                                       systemPercent: 0, idlePercent: 100, coreCount: 8))
        }
        try await store.insertBatch(samples)

        let results = try await store.querySampled(monitorID: "cpu", from: start,
                                                   to: start.addingTimeInterval(120), maxSamples: 4)

        XCTAssertLessThanOrEqual(results.count, 4)
        XCTAssertEqual(results.map { $0.timestamp }, results.map { $0.timestamp }.sorted())
    }

    // MARK: - Delete

    func testDeleteOlderThan() async throws {
        let oldDate = Date().addingTimeInterval(-7200) // 2小时前
        let recentDate = Date()

        let oldSample = CPUSample(timestamp: oldDate, usagePercent: 10.0, userPercent: 5.0,
                                  systemPercent: 5.0, idlePercent: 90.0, coreCount: 8)
        let recentSample = CPUSample(timestamp: recentDate, usagePercent: 50.0, userPercent: 30.0,
                                     systemPercent: 20.0, idlePercent: 50.0, coreCount: 8)

        try await store.insert(AnyMonitorSample(oldSample))
        try await store.insert(AnyMonitorSample(recentSample))

        // 删除1小时前的数据
        try await store.delete(olderThan: Date().addingTimeInterval(-3600))

        let now = Date()
        let results = try await store.query(monitorID: "cpu", from: oldDate.addingTimeInterval(-60), to: now.addingTimeInterval(60))
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.cpu?.usagePercent, 50.0)
    }

    // MARK: - Sample Count

    func testSampleCount() async throws {
        let count0 = try await store.sampleCount(monitorID: "cpu")
        XCTAssertEqual(count0, 0)

        let sample = CPUSample(usagePercent: 45.0, userPercent: 30.0, systemPercent: 15.0,
                               idlePercent: 55.0, coreCount: 8)
        try await store.insert(AnyMonitorSample(sample))
        try await store.insert(AnyMonitorSample(sample))

        let count2 = try await store.sampleCount(monitorID: "cpu")
        XCTAssertEqual(count2, 2)
    }

    // MARK: - Round-trip Encoding

    func testCPURoundTrip() async throws {
        let sample = CPUSample(usagePercent: 73.5, userPercent: 50.0, systemPercent: 23.5,
                               idlePercent: 26.5, coreCount: 12, frequencyGHz: 3.2)
        try await store.insert(AnyMonitorSample(sample))

        let now = Date()
        let results = try await store.query(monitorID: "cpu", from: now.addingTimeInterval(-60), to: now.addingTimeInterval(60))
        let decoded = results.first?.cpu
        XCTAssertNotNil(decoded)
        XCTAssertEqual(decoded?.usagePercent, 73.5)
        XCTAssertEqual(decoded?.coreCount, 12)
        XCTAssertEqual(decoded?.frequencyGHz, 3.2)
    }

    func testMemoryRoundTrip() async throws {
        let sample = MemorySample(usedBytes: 8_589_934_592, totalBytes: 17_179_869_184,
                                  usagePercent: 50.0, pressureLevel: .warning,
                                  swapUsedBytes: 1_073_741_824, compressedBytes: 536_870_912)
        try await store.insert(AnyMonitorSample(sample))

        let now = Date()
        let results = try await store.query(monitorID: "memory", from: now.addingTimeInterval(-60), to: now.addingTimeInterval(60))
        let decoded = results.first?.memory
        XCTAssertNotNil(decoded)
        XCTAssertEqual(decoded?.usagePercent, 50.0)
        XCTAssertEqual(decoded?.pressureLevel, .warning)
        XCTAssertEqual(decoded?.swapUsedBytes, 1_073_741_824)
    }

    func testDiskRoundTrip() async throws {
        let sample = DiskSample(volumes: [
            DiskVolumeInfo(name: "Macintosh HD", mountPoint: "/", usedBytes: 500_000_000_000,
                           totalBytes: 1_000_000_000_000, usagePercent: 50.0)
        ])
        try await store.insert(AnyMonitorSample(sample))

        let now = Date()
        let results = try await store.query(monitorID: "disk", from: now.addingTimeInterval(-60), to: now.addingTimeInterval(60))
        let decoded = results.first?.disk
        XCTAssertNotNil(decoded)
        XCTAssertEqual(decoded?.volumes.count, 1)
        XCTAssertEqual(decoded?.volumes.first?.name, "Macintosh HD")
        XCTAssertEqual(decoded?.volumes.first?.usagePercent, 50.0)
    }
}
