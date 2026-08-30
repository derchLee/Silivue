import Foundation

/// 生产环境磁盘数据提供者，使用FileManager和statfs
public final class FoundationDiskDataProvider: DiskDataProvider {
    public init() {}

    public func readDiskData() -> [DiskVolumeData] {
        let fileManager = FileManager.default
        var volumes: [DiskVolumeData] = []

        // 仅获取本地卷（排除外部磁盘/网络卷），避免 CacheDeleteCopyAvailableSpaceForVolume 系统错误
        let keys: [URLResourceKey] = [
            .volumeTotalCapacityKey,
            .volumeAvailableCapacityForImportantUsageKey,
            .volumeNameKey,
            .volumeIsLocalKey
        ]
        let mountedVolumes = fileManager.mountedVolumeURLs(
            includingResourceValuesForKeys: keys,
            options: [.skipHiddenVolumes]
        )

        guard let volumeURLs = mountedVolumes else { return volumes }

        for url in volumeURLs {
            let values: URLResourceValues
            do {
                values = try url.resourceValues(forKeys: Set(keys.map { URLResourceKey($0.rawValue) }))
            } catch {
                continue
            }

            // 跳过非本地卷（外部磁盘、网络共享等）
            if values.volumeIsLocal == false { continue }

            guard let totalBytes = values.volumeTotalCapacity,
                  let availableBytes = values.volumeAvailableCapacityForImportantUsage else {
                continue
            }

            let name = values.volumeName ?? url.lastPathComponent
            let mountPoint = url.path

            volumes.append(DiskVolumeData(
                totalBytes: UInt64(totalBytes),
                availableBytes: UInt64(availableBytes),
                volumeName: name,
                mountPoint: mountPoint
            ))
        }

        return volumes
    }
}
