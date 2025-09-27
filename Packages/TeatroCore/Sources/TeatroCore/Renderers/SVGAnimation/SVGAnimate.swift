public struct SVGAnimate {
    public let attributeName: String
    public let from: String
    public let to: String
    public let dur: Double
    public let repeatCount: String?

    public init(attributeName: String, from: String, to: String, dur: Double, repeatCount: String? = nil) {
        self.attributeName = attributeName
        self.from = from
        self.to = to
        self.dur = dur
        self.repeatCount = repeatCount
    }

    public func render() -> String {
        let repeatAttr = repeatCount.map { " repeatCount=\"\($0)\"" } ?? ""
        return """
        <animate attributeName=\"\(attributeName)\" from=\"\(from)\" to=\"\(to)\" dur=\"\(dur)s\"\(repeatAttr) fill=\"freeze\" />
        """
    }
}
