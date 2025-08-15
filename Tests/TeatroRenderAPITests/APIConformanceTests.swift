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

    func testRenderStoryboardStub() {
        let input = SimpleStoryboardInput()
        XCTAssertThrowsError(try TeatroRenderer.renderStoryboard(input))
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
