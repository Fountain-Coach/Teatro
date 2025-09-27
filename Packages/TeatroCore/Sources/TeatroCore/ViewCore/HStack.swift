public struct HStack: Layouting {
    public let children: [Renderable]
    public let alignment: Alignment
    public let spacing: Int
    public let distribution: Distribution
    public let padding: Int

    public init(
        alignment: Alignment = .leading,
        spacing: Int = 1,
        distribution: Distribution = .leading,
        padding: Int = 0,
        @ViewBuilder _ content: () -> [Renderable]
    ) {
        self.alignment = alignment
        self.spacing = spacing
        self.distribution = distribution
        self.padding = padding
        self.children = content()
    }

    public func layout() -> LayoutNode {
        .hStack(
            alignment: alignment,
            spacing: spacing,
            distribution: distribution,
            padding: padding,
            children: children.map { $0.layout() }
        )
    }
}
