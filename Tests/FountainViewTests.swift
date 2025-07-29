import XCTest
@testable import Teatro

final class FountainViewTests: XCTestCase {
    func testParseAndRender() {
        let script = """
INT. LAB - NIGHT
The robot powers up.
ROBOT
  Hello.
CUT TO:
EXT. CITY - DAY
"""
        let view = FountainSceneView(fountainText: script)
        let output = view.render()
        let lines = output.components(separatedBy: "\n")
        XCTAssertEqual(lines.first, "# INT. LAB - NIGHT")
        XCTAssertTrue(lines.contains { $0.contains("ROBOT") })
        XCTAssertTrue(lines.contains { $0.contains("Hello.") })
    }
}
