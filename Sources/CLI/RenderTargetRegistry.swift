import Foundation

public final class RenderTargetRegistry: @unchecked Sendable {
    public static let shared = RenderTargetRegistry()

    private var targets: [String: RenderTargetProtocol.Type] = [:]
    private var uniqueTargets: [RenderTargetProtocol.Type] = []

    private init() {
        // Register built-in render targets via the default plugin
        register(plugin: BuiltInRenderTargetPlugin.self)
    }

    /// Register a single render target type.
    public func register(_ target: RenderTargetProtocol.Type) {
        if !uniqueTargets.contains(where: { $0.name.lowercased() == target.name.lowercased() }) {
            uniqueTargets.append(target)
        }
        targets[target.name.lowercased()] = target
        for alias in target.aliases {
            targets[alias.lowercased()] = target
        }
    }

    /// Register a render target plugin which may provide multiple targets.
    public func register(plugin: RenderTargetPlugin.Type) {
        plugin.registerTargets(in: self)
    }

    /// Convenience static wrapper for registering a render target.
    public static func register(_ target: RenderTargetProtocol.Type) {
        shared.register(target)
    }

    /// Convenience static wrapper for registering a render target plugin.
    public static func register(plugin: RenderTargetPlugin.Type) {
        shared.register(plugin: plugin)
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
