import Foundation

public protocol RefreshTimer: AnyObject {
    var onTick: (() -> Void)? { get set }
    func start(interval: TimeInterval)
    func stop()
}
