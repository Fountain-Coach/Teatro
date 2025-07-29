public struct VStack: Layouting {
    public let children: [Renderable]
    public let alignment: Alignment
    public let padding: Int

    public init(alignment: Alignment = Alignment.leading, padding: Int = 0, @ViewBuilder _ content: () -> [Renderable]) {
        self.alignment = alignment
        self.padding = padding
        self.children = content()
    }

    public func render() -> String {
        let indent = String(repeating: " ", count: padding)
        return children.map { indent + $0.render() }.joined(separator: "\n")
    }
}
