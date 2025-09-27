import Foundation

public struct Rule: Renderable {
    public init() {}

    public func layout() -> LayoutNode {
        .raw(String(repeating: "-", count: 10))
    }
}
