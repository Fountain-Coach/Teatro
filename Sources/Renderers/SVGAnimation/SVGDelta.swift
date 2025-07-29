public struct SVGDelta {
    public let id: String
    public let animations: [String]

    public init(id: String, animations: [String]) {
        self.id = id
        self.animations = animations
    }

    public func render() -> String {
        animations.joined(separator: "\n")
    }
}
