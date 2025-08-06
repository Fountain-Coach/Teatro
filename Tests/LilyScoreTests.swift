import XCTest
@testable import Teatro

final class LilyScoreTests: XCTestCase {
    func testRenderToPDFWritesSource() {
        let score = LilyScore("c'4")
        let filename = "testScore"
        let lyPath = "/tmp/\(filename).ly"
        try? FileManager.default.removeItem(atPath: lyPath)
        score.renderToPDF(filename: filename)
        XCTAssertTrue(FileManager.default.fileExists(atPath: lyPath))
        try? FileManager.default.removeItem(atPath: lyPath)
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
