import Foundation

public struct InputCursor: Renderable {
    public init() {}

    public func layout() -> LayoutNode {
        .raw("|")
    }
}
