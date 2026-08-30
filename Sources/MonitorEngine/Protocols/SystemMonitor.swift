import Combine
import Foundation

public protocol SystemMonitor: AnyObject {
    var displayName: String { get }
    var monitorID: String { get }
    var isActive: Bool { get }
    var currentSample: AnyPublisher<AnyMonitorSample, Never> { get }
    func start(interval: RefreshInterval)
    func stop()
    func sample() async throws -> AnyMonitorSample
}
