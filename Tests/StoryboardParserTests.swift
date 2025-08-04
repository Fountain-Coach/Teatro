import XCTest
@testable import Teatro

final class StoryboardParserTests: XCTestCase {
    func testParsesScenesAndTransitions() {
        let text = """
        Scene: First
        Text: A
        Transition: crossfade 1
        Scene: Second
        Text: B
        """
        let storyboard = StoryboardParser.parse(text)
        XCTAssertEqual(storyboard.steps.count, 3)
        guard case .scene(let first) = storyboard.steps[0] else { return XCTFail("Expected scene") }
        XCTAssertEqual(first.name, "First")
        guard case .transition(let trans) = storyboard.steps[1] else { return XCTFail("Expected transition") }
        XCTAssertEqual(trans.style, .crossfade)
        XCTAssertEqual(trans.frames, 1)
        guard case .scene(let second) = storyboard.steps[2] else { return XCTFail("Expected scene") }
        XCTAssertEqual(second.name, "Second")
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
