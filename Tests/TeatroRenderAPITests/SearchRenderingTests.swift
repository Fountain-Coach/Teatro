import XCTest
@testable import TeatroRenderAPI

final class SearchRenderingTests: XCTestCase {
    func testRenderSearchProducesMarkdownList() throws {
        let query = "[ ] first task\nsecond task\n- third task"
        let input = SimpleSearchInput(query: query)
        let result = try TeatroRenderer.renderSearch(input)
        let markdown = try XCTUnwrap(result.markdown)
        XCTAssertEqual(markdown, "- [ ] first task\n- second task\n- third task")
    }
}
