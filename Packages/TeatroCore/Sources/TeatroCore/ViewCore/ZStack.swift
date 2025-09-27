// Overlays child views, as requested by root AGENT guidelines.
public struct ZStack: Renderable {
    public let children: [Renderable]
    public init(@ViewBuilder _ content: () -> [Renderable]) {
        self.children = content()
    }
    public func layout() -> LayoutNode {
        .zStack(children: children.map { $0.layout() })
    }
}
