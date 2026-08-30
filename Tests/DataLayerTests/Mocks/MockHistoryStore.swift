import Foundation
import MonitorEngine
@testable import DataLayer

final class MockHistoryStore: HistoryStore {
    var insertedSamples: [AnyMonitorSample] = []
    var insertCallCount = 0
    var stubbedQueryResult: [AnyMonitorSample] = []

    func insert(_ sample: AnyMonitorSample) async throws {
        insertedSamples.append(sample)
        insertCallCount += 1
    }

    func insertBatch(_ samples: [AnyMonitorSample]) async throws {
        insertedSamples.append(contentsOf: samples)
        insertCallCount += samples.count
    }

    func query(monitorID: String, from: Date, to: Date) async throws -> [AnyMonitorSample] {
        return stubbedQueryResult.filter { $0.monitorID == monitorID }
    }

    var deletedBefore: Date?
    var deleteCallCount = 0

    func delete(olderThan date: Date) async throws {
        deletedBefore = date
        deleteCallCount += 1
    }

    var stubbedSampleCount: Int = 0

    func sampleCount(monitorID: String) async throws -> Int {
        return stubbedSampleCount
    }
}
