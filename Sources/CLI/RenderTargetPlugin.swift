import Foundation

/// A plugin that registers custom render targets with the registry.
public protocol RenderTargetPlugin {
    /// Register one or more `RenderTargetProtocol` types with the provided registry.
    static func registerTargets(in registry: RenderTargetRegistry)
}
