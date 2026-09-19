import Foundation
import MonitorEngine

/// Detects a sustained system-memory increase. It does not attribute memory use to an app.
public final class MemoryGrowthDetector {
    private let minimumDuration: TimeInterval
    private let minimumGrowthBytes: UInt64
    private var baseline: MemorySample?
    private var didAlert = false

    public init(minimumDuration: TimeInterval = 600,
                minimumGrowthBytes: UInt64 = 1 * 1_024 * 1_024 * 1_024) {
        self.minimumDuration = minimumDuration
        self.minimumGrowthBytes = minimumGrowthBytes
    }

    public func shouldAlert(for sample: MemorySample) -> Bool {
        guard let baseline else {
            self.baseline = sample
            return false
        }
        if sample.usedBytes <= baseline.usedBytes {
            self.baseline = sample
            didAlert = false
            return false
        }
        guard !didAlert,
              sample.timestamp.timeIntervalSince(baseline.timestamp) >= minimumDuration,
              sample.usedBytes >= baseline.usedBytes + minimumGrowthBytes else { return false }
        didAlert = true
        return true
    }
}
