import Foundation

public final class RenderTargetRegistry: @unchecked Sendable {
    public static let shared = RenderTargetRegistry()

    private var targets: [String: RenderTargetProtocol.Type] = [:]
    private var uniqueTargets: [RenderTargetProtocol.Type] = []

    private init() {
        register(HTMLTarget.self)
        register(SVGTarget.self)
        register(PNGTarget.self)
        register(MarkdownTarget.self)
        register(CodexTarget.self)
        register(SVGAnimatedTarget.self)
        register(CsoundTarget.self)
        register(UMPTarget.self)
    }

    public func register(_ target: RenderTargetProtocol.Type) {
        if !uniqueTargets.contains(where: { $0.name.lowercased() == target.name.lowercased() }) {
            uniqueTargets.append(target)
        }
        targets[target.name.lowercased()] = target
        for alias in target.aliases {
            targets[alias.lowercased()] = target
        }
    }

    public func lookup(_ name: String) -> RenderTargetProtocol.Type? {
        targets[name.lowercased()]
    }

    public var allTargets: [RenderTargetProtocol.Type] {
        uniqueTargets
    }

    public var availableFormats: [String] {
        allTargets.map { $0.name }.sorted()
    }
}
