import Foundation

/// Public application metadata supplied by NSWorkspace. No process inspection is performed.
public struct RunningAppContext: Equatable {
    public let name: String
    public let bundleIdentifier: String?

    public init(name: String, bundleIdentifier: String?) {
        self.name = name
        self.bundleIdentifier = bundleIdentifier
    }
}

public struct DeveloperWorkloadContext: Identifiable, Equatable {
    public let id: String
    public let title: String
    public let detail: String
    public let isContextOnly: Bool

    public init(id: String, title: String, detail: String, isContextOnly: Bool = true) {
        self.id = id
        self.title = title
        self.detail = detail
        self.isContextOnly = isContextOnly
    }
}

/// Identifies broad developer-workload categories from public bundle identifiers only.
/// These are workload context signals, never claims about resource attribution.
public struct DeveloperWorkloadClassifier {
    public init() {}

    public func classify(_ apps: [RunningAppContext]) -> [DeveloperWorkloadContext] {
        let identifiers = Set(apps.compactMap(\.bundleIdentifier))
        var contexts: [DeveloperWorkloadContext] = []
        if identifiers.contains(where: { $0 == "com.apple.dt.Xcode" || $0 == "com.microsoft.VSCode" || $0 == "com.todesktop.230313mzl4w4u92" }) {
            contexts.append(DeveloperWorkloadContext(id: "ide", title: "IDE", detail: AppLocalization.text("A development environment is currently running.")))
        }
        if identifiers.contains(where: { $0 == "com.docker.docker" || $0 == "io.orbstack" }) {
            contexts.append(DeveloperWorkloadContext(id: "container", title: AppLocalization.text("Container environment"), detail: AppLocalization.text("A local container environment is currently running.")))
        }
        if identifiers.contains(where: { $0 == "com.ollama.Ollama" || $0 == "com.lmstudio" }) {
            contexts.append(DeveloperWorkloadContext(id: "local-ai", title: AppLocalization.text("Local AI runtime"), detail: AppLocalization.text("A local AI application is currently running.")))
        }
        if identifiers.contains(where: { $0 == "com.apple.Terminal" || $0 == "com.googlecode.iterm2" || $0 == "dev.warp.Warp-Stable" }) {
            contexts.append(DeveloperWorkloadContext(id: "terminal", title: AppLocalization.text("Terminal"), detail: AppLocalization.text("A terminal application is currently running.")))
        }
        return contexts
    }
}
