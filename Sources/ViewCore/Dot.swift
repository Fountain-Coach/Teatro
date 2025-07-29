import Foundation

public struct Dot: Renderable {
    public let color: String
    public let diameter: Int

    public init(color: String = "black", diameter: Int = 10) {
        self.color = color
        self.diameter = diameter
    }

    public func render() -> String {
        "\u{25CF}" // ●
    }
}
