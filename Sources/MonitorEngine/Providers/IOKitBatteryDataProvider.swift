import Foundation
import IOKit
import IOKit.ps

public final class IOKitBatteryDataProvider: BatteryDataProvider {
    public init() {}

    public func readBatteryData() -> BatteryRawData {
        guard let psInfo = IOPSCopyPowerSourcesInfo() else {
            return noBatteryData
        }
        let psInfoRef = psInfo.takeRetainedValue()
        guard let psSources = IOPSCopyPowerSourcesList(psInfoRef) else {
            return noBatteryData
        }

        let sourceIDs = psSources.takeRetainedValue() as [CFTypeRef]
        for sourceID in sourceIDs {
            guard let desc = IOPSGetPowerSourceDescription(psInfoRef, sourceID) else { continue }
            guard let source = desc.takeUnretainedValue() as? [String: Any] else { continue }
            guard source[kIOPSIsPresentKey] as? Bool != false else { continue }
            guard let state = source[kIOPSPowerSourceStateKey] as? String else { continue }

            let charge = (source[kIOPSCurrentCapacityKey] as? Int).map { Double($0) } ?? 100
            let isCharging = source[kIOPSIsChargingKey] as? Bool ?? false
            let timeToEmpty = source[kIOPSTimeToEmptyKey] as? Int ?? -1
            let timeToFull = source[kIOPSTimeToFullChargeKey] as? Int ?? -1
            let designCapacity = source[kIOPSDesignCapacityKey] as? Int ?? 0
            let maxCapacity = source[kIOPSMaxCapacityKey] as? Int ?? 0
            let healthPercent = designCapacity > 0 && maxCapacity > 0 && maxCapacity <= designCapacity
                ? Double(maxCapacity) / Double(designCapacity) * 100.0
                : 0

            let timeRemaining: Int
            if isCharging {
                timeRemaining = timeToFull > 0 ? timeToFull : -1
            } else {
                timeRemaining = timeToEmpty > 0 ? timeToEmpty : -1
            }

            return BatteryRawData(
                chargePercent: charge,
                isCharging: isCharging,
                healthPercent: healthPercent,
                cycleCount: 0,
                timeRemaining: timeRemaining,
                powerSource: state,
                designCapacity: designCapacity,
                maxCapacity: maxCapacity
            )
        }

        return noBatteryData
    }

    private var noBatteryData: BatteryRawData {
        BatteryRawData(
            chargePercent: 0, isCharging: false, healthPercent: 0,
            cycleCount: 0, timeRemaining: -1, powerSource: "No Battery",
            designCapacity: 0, maxCapacity: 0
        )
    }
}
