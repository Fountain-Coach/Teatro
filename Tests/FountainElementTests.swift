import XCTest
@testable import Teatro

final class FountainElementTests: XCTestCase {
    func testRenderVariants() {
        XCTAssertEqual(FountainElement.sceneHeading("INT. HOUSE").render(), "# INT. HOUSE")
        XCTAssertEqual(FountainElement.characterCue("John").render(), "\nJOHN")
        XCTAssertEqual(FountainElement.dialogue("Hello").render(), "\tHello")
        XCTAssertEqual(FountainElement.action("Act").render(), "Act")
        XCTAssertEqual(FountainElement.transition("CUT TO").render(), "CUT TO >>")
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
