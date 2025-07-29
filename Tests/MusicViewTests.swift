import XCTest
@testable import Teatro

final class MusicViewTests: XCTestCase {
    func testLilyScoreRender() {
        let score = LilyScore("c d e f")
        XCTAssertEqual(score.render(), "c d e f")
    }
}
