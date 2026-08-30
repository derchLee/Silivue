import Foundation

/// 生产环境定时器，使用DispatchSourceTimer
public final class DispatchRefreshTimer: RefreshTimer {
    public var onTick: (() -> Void)?
    private var timer: DispatchSourceTimer?

    public init() {}

    public func start(interval: TimeInterval) {
        stop()

        let source = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .utility))
        source.schedule(deadline: .now(), repeating: interval, leeway: .milliseconds(50))
        source.setEventHandler { [weak self] in
            self?.onTick?()
        }
        source.resume()
        timer = source
    }

    public func stop() {
        timer?.cancel()
        timer = nil
    }

    deinit {
        timer?.cancel()
    }
}
