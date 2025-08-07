public struct TeatroIcon: Renderable {
    public let symbol: String

    public init(_ symbol: String) {
        self.symbol = symbol
    }

    public func layout() -> LayoutNode {
        .raw("\u{25C9} \(symbol)")
    }
}
