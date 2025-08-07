public struct HStack: Layouting {
    public let children: [Renderable]
    public let alignment: Alignment
    public let padding: Int

    public init(alignment: Alignment = Alignment.leading, padding: Int = 0, @ViewBuilder _ content: () -> [Renderable]) {
        self.alignment = alignment
        self.padding = padding
        self.children = content()
    }

    public func layout() -> LayoutNode {
        .hStack(alignment: alignment, padding: padding, children: children.map { $0.layout() })
    }
}
