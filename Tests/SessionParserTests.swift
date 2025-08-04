import XCTest
@testable import Teatro

final class SessionParserTests: XCTestCase {
    func testParsesRawText() {
        let text = "Line one\nLine two"
        let session = SessionParser.parse(text)
        XCTAssertEqual(session.text, text)
        XCTAssertEqual(session.render(), text)
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
