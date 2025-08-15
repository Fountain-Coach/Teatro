import XCTest
@testable import TeatroRenderAPI

final class APIConformanceTests: XCTestCase {
    func testRenderScriptRenders() throws {
        let script = """
        INT. SCENE - DAY

        JOHN
        Hello.
        """
        let input = SimpleScriptInput(fountainText: script)
        let result = try TeatroRenderer.renderScript(input)
        XCTAssertNotNil(result.svg)
    }

    func testRenderStoryboardRenders() throws {
        let dsl = """
        Scene: Test
        Text: Hi
        """
        let input = SimpleStoryboardInput(storyboardDSL: dsl)
        let result = try TeatroRenderer.renderStoryboard(input)
        XCTAssertNotNil(result.svg)
    }

    func testRenderSessionRenders() throws {
        let input = SimpleSessionInput(logText: "$ test\n")
        let result = try TeatroRenderer.renderSession(input)
        XCTAssertNotNil(result.markdown)
    }

    func testRenderSearchRenders() throws {
        let input = SimpleSearchInput(query: "task one\n")
        let result = try TeatroRenderer.renderSearch(input)
        XCTAssertNotNil(result.markdown)
    }
}
