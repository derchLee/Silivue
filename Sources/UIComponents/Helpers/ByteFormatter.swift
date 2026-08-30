import Foundation

public struct ByteFormatter {
    public static func format(_ bytes: UInt64) -> String {
        let units = ["B", "KB", "MB", "GB", "TB"]
        var value = Double(bytes)
        var unitIndex = 0

        while value >= 1024 && unitIndex < units.count - 1 {
            value /= 1024
            unitIndex += 1
        }

        if unitIndex == 0 {
            return "\(Int(value)) \(units[unitIndex])"
        }
        return String(format: "%.2f \(units[unitIndex])", value)
    }

    public static func formatSpeed(_ bytesPerSec: Double) -> String {
        let formatted = format(UInt64(max(0, bytesPerSec)))
        return "\(formatted)/s"
    }
}