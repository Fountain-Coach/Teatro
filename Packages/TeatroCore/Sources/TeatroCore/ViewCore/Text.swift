public struct Text: Renderable {
    public let content: String
    public let style: TextStyle

    public init(_ content: String, style: TextStyle = .plain) {
        self.content = content
        self.style = style
    }

    public func layout() -> LayoutNode {
        .text(content, style: style)
    }
}
