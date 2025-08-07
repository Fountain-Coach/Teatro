import Foundation

/// Registry that holds available renderer plugins.
public final class RendererRegistry: @unchecked Sendable {
    public static let shared = RendererRegistry()

    private var byIdentifier: [String: RendererPlugin.Type] = [:]
    private var byExtension: [String: RendererPlugin.Type] = [:]
    private var ordered: [RendererPlugin.Type] = []

    private init() {
        // Register built-in renderers
        register(HTMLRenderer.self)
        register(SVGRenderer.self)
        register(ImageRenderer.self)
        register(MarkdownRenderer.self)
        register(CodexPreviewer.self)
        register(CSDRenderer.self)
        register(MIDIRenderer.self)
        register(SVGAnimatedRenderer.self)
        register(UMPRenderer.self)
    }

    public func register(_ plugin: RendererPlugin.Type) {
        if !ordered.contains(where: { $0.identifier.lowercased() == plugin.identifier.lowercased() }) {
            ordered.append(plugin)
        }
        byIdentifier[plugin.identifier.lowercased()] = plugin
        for ext in plugin.fileExtensions {
            byExtension[ext.lowercased()] = plugin
        }
    }

    public static func register(_ plugin: RendererPlugin.Type) {
        shared.register(plugin)
    }

    public func plugin(for identifier: String) -> RendererPlugin.Type? {
        byIdentifier[identifier.lowercased()]
    }

    public func pluginForExtension(_ ext: String) -> RendererPlugin.Type? {
        byExtension[ext.lowercased()]
    }

    public var allPlugins: [RendererPlugin.Type] { ordered }

    public var availableIdentifiers: [String] {
        ordered.map { $0.identifier }.sorted()
    }
}
