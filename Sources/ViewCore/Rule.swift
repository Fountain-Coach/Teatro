import Foundation

public struct Rule: Renderable {
    public init() {}

    public func render() -> String {
        String(repeating: "-", count: 10)
    }
}
