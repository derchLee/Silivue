import Foundation
import IOKit

public final class IOKitSMCDataProvider: TemperatureDataProvider {
    public init() {}

    public func readTemperatureData() -> TemperatureRawData {
        let connect = openSMCConnection()
        defer { closeSMCConnection(connect) }

        guard connect != 0 else {
            return TemperatureRawData(cpuTemperature: nil, gpuTemperature: nil, fanSpeeds: [])
        }

        let cpuTemp = readTemperature(connect: connect, key: "TC0P")
        let gpuTemp = readTemperature(connect: connect, key: "TG0P")
        let fanSpeeds = readFanSpeeds(connect: connect)

        return TemperatureRawData(cpuTemperature: cpuTemp, gpuTemperature: gpuTemp, fanSpeeds: fanSpeeds)
    }

    // MARK: - SMC Connection

    private func openSMCConnection() -> UInt32 {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSMC"))
        defer { IOObjectRelease(service) }

        guard service != 0 else { return 0 }

        var connect: UInt32 = 0
        let result = IOServiceOpen(service, mach_task_self_, 0, &connect)
        guard result == kIOReturnSuccess else { return 0 }
        return connect
    }

    private func closeSMCConnection(_ connect: UInt32) {
        guard connect != 0 else { return }
        IOServiceClose(connect)
    }

    // MARK: - SMC Key Reading

    private func readTemperature(connect: UInt32, key: String) -> Double? {
        guard let data = readSMCKey(connect: connect, key: key) else { return nil }

        // SPxx data type: 2 bytes, big-endian, value * 100 (e.g., 5540 = 55.40°C)
        // flt data type: 4 bytes, IEEE 754 float
        if data.count >= 2 {
            let dataType = smcDataType(connect: connect, key: key)
            if dataType == fourCharCode(from: "sp78") || dataType == fourCharCode(from: "sp8 ") {
                let intVal = Int(data[0])
                let fracVal = Int(data[1])
                return Double(intVal) + Double(fracVal) / 256.0
            } else {
                // Generic 2-byte big-endian: value / 100.0
                let raw = (Int(data[0]) << 8) | Int(data[1])
                return Double(raw) / 100.0
            }
        }
        return nil
    }

    private func readFanSpeeds(connect: UInt32) -> [FanSpeedInfo] {
        guard let fanCountData = readSMCKey(connect: connect, key: "FNum"),
              fanCountData.count >= 1 else {
            return []
        }

        let fanCount = Int(fanCountData[0])
        var fans: [FanSpeedInfo] = []

        for i in 0..<fanCount {
            let actualKey = String(format: "F%1dAc", i)
            let maxKey = String(format: "F%1dMx", i)

            let actualRPM: Int
            if let actualData = readSMCKey(connect: connect, key: actualKey), actualData.count >= 2 {
                actualRPM = (Int(actualData[0]) << 8) | Int(actualData[1])
            } else {
                actualRPM = 0
            }

            let maxRPM: Int
            if let maxData = readSMCKey(connect: connect, key: maxKey), maxData.count >= 2 {
                maxRPM = (Int(maxData[0]) << 8) | Int(maxData[1])
            } else {
                maxRPM = 0
            }

            fans.append(FanSpeedInfo(currentRPM: actualRPM, maxRPM: maxRPM, label: "Fan \(i)"))
        }

        return fans
    }

    // MARK: - Low-level SMC Access

    private func readSMCKey(connect: UInt32, key: String) -> Data? {
        var input = SMCKeyStruct(
            key: fourCharCode(from: key),
            info: SMCInfoStruct(
                dataSize: 0,
                dataType: 0,
                dataValue: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
            )
        )

        var output = SMCInfoStruct(
            dataSize: 0,
            dataType: 0,
            dataValue: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
        )
        var outputSize = MemoryLayout<SMCInfoStruct>.size

        // KSMCReadKey = index 5
        let result = withUnsafeMutablePointer(to: &input) { inputPtr in
            withUnsafeMutablePointer(to: &output) { outputPtr in
                IOConnectCallStructMethod(connect, 5, inputPtr, MemoryLayout<SMCKeyStruct>.size, outputPtr, &outputSize)
            }
        }

        guard result == kIOReturnSuccess else { return nil }
        guard output.dataSize > 0 else { return nil }

        return Data(bytes: &output.dataValue, count: Int(output.dataSize))
    }

    private func smcDataType(connect: UInt32, key: String) -> UInt32 {
        var input = SMCKeyStruct(
            key: fourCharCode(from: key),
            info: SMCInfoStruct(
                dataSize: 0,
                dataType: 0,
                dataValue: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
            )
        )

        var output = SMCInfoStruct(
            dataSize: 0,
            dataType: 0,
            dataValue: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
        )
        var outputSize = MemoryLayout<SMCInfoStruct>.size

        let result = withUnsafeMutablePointer(to: &input) { inputPtr in
            withUnsafeMutablePointer(to: &output) { outputPtr in
                IOConnectCallStructMethod(connect, 5, inputPtr, MemoryLayout<SMCKeyStruct>.size, outputPtr, &outputSize)
            }
        }

        guard result == kIOReturnSuccess else { return 0 }
        return output.dataType
    }

    // MARK: - Helper

    private func fourCharCode(from string: String) -> UInt32 {
        guard string.count == 4 else { return 0 }
        var result: UInt32 = 0
        for char in string.utf8 {
            result = (result << 8) | UInt32(char)
        }
        return result
    }
}

// MARK: - SMC Structs

private struct SMCKeyStruct {
    var key: UInt32
    var info: SMCInfoStruct
}

private struct SMCInfoStruct {
    var dataSize: UInt32
    var dataType: UInt32
    var dataValue: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
                    UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
                    UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
                    UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8)
}
