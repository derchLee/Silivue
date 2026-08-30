import Foundation
import MonitorEngine

/// 基于内存的HistoryStore实现，用于测试和临时场景
public final class InMemoryHistoryStore: HistoryStore {
    private var samples: [String: [AnyMonitorSample]] = [:]

    public init() {}

    public func insert(_ sample: AnyMonitorSample) async throws {
        samples[sample.monitorID, default: []].append(sample)
    }

    public func insertBatch(_ samples: [AnyMonitorSample]) async throws {
        for sample in samples {
            try await insert(sample)
        }
    }

    public func query(monitorID: String, from: Date, to: Date) async throws -> [AnyMonitorSample] {
        guard let monitorSamples = samples[monitorID] else { return [] }
        return monitorSamples.filter { sample in
            sample.timestamp >= from && sample.timestamp <= to
        }
    }

    public func delete(olderThan date: Date) async throws {
        for key in samples.keys {
            samples[key]?.removeAll { $0.timestamp < date }
        }
    }

    public func sampleCount(monitorID: String) async throws -> Int {
        return samples[monitorID]?.count ?? 0
    }
}