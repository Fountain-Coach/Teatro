import Foundation

public struct CsoundScore: Renderable {
    public let orchestra: String
    public let score: String

    public init(orchestra: String, score: String) {
        self.orchestra = orchestra
        self.score = score
    }

    public func render() -> String {
        """
        <CsoundSynthesizer>
        <Orchestra>
        \(orchestra)
        </Orchestra>
        <Score>
        \(score)
        </Score>
        </CsoundSynthesizer>
        """
    }
}
