import Foundation
import MonitorEngine

public protocol HistoryStore: SamplePersistence {
    func insert(_ sample: AnyMonitorSample) async throws
    func insertBatch(_ samples: [AnyMonitorSample]) async throws
    func query(monitorID: String, from: Date, to: Date) async throws -> [AnyMonitorSample]
    func querySampled(monitorID: String, from: Date, to: Date, maxSamples: Int) async throws -> [AnyMonitorSample]
    func delete(olderThan: Date) async throws
    func sampleCount(monitorID: String) async throws -> Int
}

public extension HistoryStore {
    func querySampled(monitorID: String, from: Date, to: Date, maxSamples: Int) async throws -> [AnyMonitorSample] {
        let samples = try await query(monitorID: monitorID, from: from, to: to)
        guard maxSamples > 0, samples.count > maxSamples else { return samples }
        let step = max(1, Int(ceil(Double(samples.count) / Double(maxSamples))))
        return samples.enumerated().compactMap { index, sample in index.isMultiple(of: step) ? sample : nil }
    }
}
