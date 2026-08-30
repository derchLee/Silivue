@testable import MonitorEngine

final class MockDiskDataProvider: DiskDataProvider {
    var stubbedVolumes: [DiskVolumeData]
    private(set) var callCount = 0

    init(stubbedVolumes: [DiskVolumeData] = []) {
        self.stubbedVolumes = stubbedVolumes
    }

    func readDiskData() -> [DiskVolumeData] {
        callCount += 1
        return stubbedVolumes
    }
}
