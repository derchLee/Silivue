import Foundation
import IOKit
import IOKit.ps

public final class IOKitBatteryDataProvider: BatteryDataProvider {
    public init() {}

    public func readBatteryData() -> BatteryRawData {
        let smartBattery = readAppleSmartBattery()

        // 无真实电池（Mac mini/Mac Studio/台式机）：designCapacity 或 cycleCount 为 0 表示无电池
        guard smartBattery.designCapacity > 0 || smartBattery.cycleCount > 0 else {
            return BatteryRawData(
                chargePercent: 0, isCharging: false, healthPercent: 0,
                cycleCount: 0, timeRemaining: -1, powerSource: "No Battery",
                designCapacity: 0, maxCapacity: 0, amperage: 0, voltage: 0
            )
        }

        let (chargePercent, timeRemaining, powerSource) = readIOPSPowerSource()
        let healthPercent = smartBattery.designCapacity > 0
            ? Double(smartBattery.maxCapacity) / Double(smartBattery.designCapacity) * 100.0
            : 100.0

        return BatteryRawData(
            chargePercent: chargePercent,
            isCharging: smartBattery.isCharging,
            healthPercent: healthPercent,
            cycleCount: smartBattery.cycleCount,
            timeRemaining: timeRemaining,
            powerSource: powerSource,
            designCapacity: smartBattery.designCapacity,
            maxCapacity: smartBattery.maxCapacity,
            amperage: smartBattery.amperage,
            voltage: smartBattery.voltage
        )
    }

    private func readIOPSPowerSource() -> (chargePercent: Double, timeRemaining: Int, powerSource: String) {
        guard let psInfo = IOPSCopyPowerSourcesInfo() else {
            return (chargePercent: 100, timeRemaining: -1, powerSource: "AC Power")
        }
        let psInfoRef = psInfo.takeRetainedValue()
        guard let psSources = IOPSCopyPowerSourcesList(psInfoRef) else {
            return (chargePercent: 100, timeRemaining: -1, powerSource: "AC Power")
        }

        let sourceIDs = psSources.takeRetainedValue() as [CFTypeRef]
        for sourceID in sourceIDs {
            guard let desc = IOPSGetPowerSourceDescription(psInfoRef, sourceID) else { continue }
            // IOPSGetPowerSourceDescription follows the Get rule. The dictionary is
            // owned by psInfo and must not be released by the caller.
            guard let source = desc.takeUnretainedValue() as? [String: Any] else { continue }
            guard let state = source[kIOPSPowerSourceStateKey] as? String else { continue }

            let charge = (source[kIOPSCurrentCapacityKey] as? Int).map { Double($0) } ?? 100
            let timeToEmpty = source[kIOPSTimeToEmptyKey] as? Int ?? -1
            let timeToFull = source[kIOPSTimeToFullChargeKey] as? Int ?? -1

            let timeRemaining: Int
            if state == "AC Power" {
                timeRemaining = timeToFull > 0 ? timeToFull : -1
            } else {
                timeRemaining = timeToEmpty > 0 ? timeToEmpty : -1
            }

            return (chargePercent: charge, timeRemaining: timeRemaining, powerSource: state)
        }

        return (chargePercent: 100, timeRemaining: -1, powerSource: "AC Power")
    }

    private func readAppleSmartBattery() -> (cycleCount: Int, designCapacity: Int, maxCapacity: Int, isCharging: Bool, amperage: Int, voltage: Double) {
        let mainPort = kIOMainPortDefault
        let service = IOServiceGetMatchingService(mainPort, IOServiceMatching("AppleSmartBattery"))
        defer { IOObjectRelease(service) }

        guard service != 0 else {
            return (cycleCount: 0, designCapacity: 0, maxCapacity: 0, isCharging: false, amperage: 0, voltage: 0)
        }

        var properties: Unmanaged<CFMutableDictionary>?
        guard IORegistryEntryCreateCFProperties(service, &properties, kCFAllocatorDefault, 0) == kIOReturnSuccess,
              let dict = properties?.takeRetainedValue() as? [String: Any] else {
            return (cycleCount: 0, designCapacity: 0, maxCapacity: 0, isCharging: false, amperage: 0, voltage: 0)
        }

        let cycleCount = (dict["CycleCount"] as? Int) ?? 0
        let designCapacity = (dict["DesignCapacity"] as? Int) ?? 0
        let maxCapacity = (dict["MaxCapacity"] as? Int) ?? 0
        let isCharging = (dict["IsCharging"] as? Bool) ?? false
        let amperage = (dict["Amperage"] as? Int) ?? 0
        let voltageMV = (dict["Voltage"] as? Int) ?? 0

        return (cycleCount: cycleCount, designCapacity: designCapacity, maxCapacity: maxCapacity,
                isCharging: isCharging, amperage: amperage, voltage: Double(voltageMV) / 1000.0)
    }
}
