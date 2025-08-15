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

    func testRenderSessionStub() {
        let input = SimpleSessionInput(logText: "")
        XCTAssertThrowsError(try TeatroRenderer.renderSession(input))
    }

    func testRenderSearchStub() {
        let input = SimpleSearchInput(query: "")
        XCTAssertThrowsError(try TeatroRenderer.renderSearch(input))
    }
}
