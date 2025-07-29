public struct TeatroIcon: Renderable {
    public let symbol: String

    public init(_ symbol: String) {
        self.symbol = symbol
    }

    public func render() -> String {
        "\u{25C9} \(symbol)" // use ◉ (U+25C9)
    }
}
