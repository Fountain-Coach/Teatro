import Foundation

public struct Panel: Renderable {
    public let width: Int
    public let height: Int
    public let cornerRadius: Int
    public let content: [Renderable]

    public init(width: Int, height: Int, cornerRadius: Int = 0, @ViewBuilder content: () -> [Renderable]) {
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    public func layout() -> LayoutNode {
        .panel(width: width, height: height, cornerRadius: cornerRadius, children: content.map { $0.layout() })
    }
}
