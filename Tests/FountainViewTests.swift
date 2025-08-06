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

    func testParentheticalMapsToDialogue() {
        let script = """
JOHN
(whispers)
Hello
"""
        let elements = FountainRenderer.parse(script)
        XCTAssertEqual(elements.count, 3)
        if case .dialogue(let txt) = elements[1] {
            XCTAssertEqual(txt, "(whispers)")
        } else {
            XCTFail("Expected parenthetical to map to dialogue")
        }
    }
}
