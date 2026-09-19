import XCTest
@testable import DataLayer

final class DeveloperWorkloadClassifierTests: XCTestCase {
    func testRecognizesDeveloperWorkloadCategoriesFromPublicAppMetadata() {
        let contexts = DeveloperWorkloadClassifier().classify([
            RunningAppContext(name: "Xcode", bundleIdentifier: "com.apple.dt.Xcode"),
            RunningAppContext(name: "Docker", bundleIdentifier: "com.docker.docker"),
            RunningAppContext(name: "Ollama", bundleIdentifier: "com.ollama.Ollama")
        ])

        XCTAssertEqual(contexts.map(\.title), ["IDE", "Container environment", "Local AI runtime"])
        XCTAssertTrue(contexts.allSatisfy { $0.isContextOnly })
    }

    func testDoesNotClassifyUnknownApps() {
        let contexts = DeveloperWorkloadClassifier().classify([
            RunningAppContext(name: "Notes", bundleIdentifier: "com.apple.Notes")
        ])
        XCTAssertTrue(contexts.isEmpty)
    }
}
