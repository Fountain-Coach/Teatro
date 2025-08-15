import XCTest
@testable import TeatroRenderAPI

final class SessionRenderingTests: XCTestCase {
    func testRenderSessionProducesMarkdownAndMarkers() throws {
        let log = """
$ echo hi
hi
$ ls
file
"""
        let input = SimpleSessionInput(logText: log)
        let result = try TeatroRenderer.renderSession(input)
        let markdown = try XCTUnwrap(result.markdown)
        XCTAssertTrue(markdown.contains("```session"))
        XCTAssertTrue(markdown.contains("$ echo hi"))
        XCTAssertTrue(markdown.contains("\"line\" : 1"))
        XCTAssertTrue(markdown.contains("\"command\" : \"echo hi\""))
    }
}
