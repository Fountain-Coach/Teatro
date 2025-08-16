import XCTest
@testable import Teatro

final class SessionParserTests: XCTestCase {
    func testParsesRawText() throws {
        let url = Bundle.module.url(forResource: "sample", withExtension: "session")!
        let text = try String(contentsOf: url, encoding: .utf8)
        let session = SessionParser.parse(text)
        XCTAssertEqual(session.text, text)
        XCTAssertEqual(session.render(), text)
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
