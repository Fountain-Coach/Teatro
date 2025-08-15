import XCTest
@testable import TeatroRenderAPI

final class APIConformanceTests: XCTestCase {
    func testRenderScriptStub() {
        let input = SimpleScriptInput(fountainText: "INT. SCENE")
        XCTAssertThrowsError(try TeatroRenderer.renderScript(input))
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
