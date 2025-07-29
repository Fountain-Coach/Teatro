public struct SVGAnimateTransform {
    public let type: String
    public let from: String
    public let to: String
    public let dur: Double

    public init(type: String, from: String, to: String, dur: Double) {
        self.type = type
        self.from = from
        self.to = to
        self.dur = dur
    }

    public func render() -> String {
        return """
        <animateTransform attributeName=\"transform\" type=\"\(type)\" from=\"\(from)\" to=\"\(to)\" dur=\"\(dur)s\" fill=\"freeze\" />
        """
    }
}
