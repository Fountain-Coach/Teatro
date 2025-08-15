import XCTest
@testable import TeatroRenderAPI

final class ScriptRenderingTests: XCTestCase {
    func testRenderScriptProducesSVGAndSynopsis() throws {
        let script = """
        = Opening scene
        INT. HOUSE - DAY
        
        JOHN
        Hello there.
        """
        let input = SimpleScriptInput(fountainText: script)
        let result = try TeatroRenderer.renderScript(input)
        let svgString = String(data: try XCTUnwrap(result.svg), encoding: .utf8)
        XCTAssertNotNil(svgString)
        XCTAssertEqual(result.markdown?.trimmingCharacters(in: .whitespacesAndNewlines), "- Opening scene")
    }
}
