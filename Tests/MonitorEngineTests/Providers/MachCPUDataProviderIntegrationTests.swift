import XCTest
@testable import MonitorEngine

/// 集成测试：验证真实系统API返回合理数据
/// 这些测试调用真实的C API，仅在macOS上运行
final class MachCPUDataProviderIntegrationTests: XCTestCase {

    func testReturnsNonZeroTicks() {
        let provider = MachCPUDataProvider()
        let data = provider.readCPUTicks()

        let total = UInt64(data.user) + UInt64(data.system) + UInt64(data.idle) + UInt64(data.nice)
        XCTAssertGreaterThan(total, 0, "Total CPU ticks should be non-zero on any running system")
    }

    func testTicksIncreaseOverTime() async {
        let provider = MachCPUDataProvider()
        let first = provider.readCPUTicks()
        let firstTotal = UInt64(first.user) + UInt64(first.system) + UInt64(first.idle) + UInt64(first.nice)

        var latestTotal = firstTotal
        for _ in 0..<10 where latestTotal <= firstTotal {
            try? await Task.sleep(nanoseconds: 100_000_000)
            let latest = provider.readCPUTicks()
            latestTotal = UInt64(latest.user) + UInt64(latest.system) + UInt64(latest.idle) + UInt64(latest.nice)
        }

        XCTAssertGreaterThan(latestTotal, firstTotal, "CPU ticks should increase within one second")
    }
}
