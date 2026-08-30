import Foundation
@testable import MonitorEngine

final class MockRefreshTimer: RefreshTimer {
    var onTick: (() -> Void)?
    private(set) var startCallCount = 0
    private(set) var stopCallCount = 0
    private(set) var lastInterval: TimeInterval?

    func start(interval: TimeInterval) {
        startCallCount += 1
        lastInterval = interval
    }

    func stop() {
        stopCallCount += 1
    }

    /// 手动触发定时器tick（测试用）
    func fireTick() {
        onTick?()
    }
}
