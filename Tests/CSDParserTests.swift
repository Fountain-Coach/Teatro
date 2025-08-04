import XCTest
@testable import Teatro

final class CSDParserTests: XCTestCase {
    func testParsesOrchestraAndScore() throws {
        let csd = """
        <CsoundSynthesizer>
        <Orchestra>
        f 1 0 0 10 1
        </Orchestra>
        <Score>
        i1 0 1 0.5
        </Score>
        </CsoundSynthesizer>
        """
        let score = try CSDParser.parse(csd)
        XCTAssertEqual(score.orchestra.trimmingCharacters(in: .whitespacesAndNewlines), "f 1 0 0 10 1")
        XCTAssertEqual(score.score.trimmingCharacters(in: .whitespacesAndNewlines), "i1 0 1 0.5")
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
