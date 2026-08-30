import Foundation
import MonitorEngine

public protocol HistoryStore: SamplePersistence {
    func insert(_ sample: AnyMonitorSample) async throws
    func insertBatch(_ samples: [AnyMonitorSample]) async throws
    func query(monitorID: String, from: Date, to: Date) async throws -> [AnyMonitorSample]
    func delete(olderThan: Date) async throws
    func sampleCount(monitorID: String) async throws -> Int
}
