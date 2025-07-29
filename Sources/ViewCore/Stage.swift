public struct Stage: Renderable {
    public let title: String
    public let content: Renderable

    public init(title: String, content: () -> Renderable) {
        self.title = title
        self.content = content()
    }

    public func render() -> String {
        "[Stage: \(title)]\n" + content.render()
    }
}
