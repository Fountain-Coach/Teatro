import XCTest
@testable import Teatro

final class StoryboardParserTests: XCTestCase {
    func testParsesScenesAndTransitions() throws {
        let text = """
        Scene: First
        Text: A
        Transition: crossfade 1
        Scene: Second
        Text: B
        """
        let storyboard = try StoryboardParser.parse(text)
        XCTAssertEqual(storyboard.steps.count, 3)
        guard case .scene(let first) = storyboard.steps[0] else { return XCTFail("Expected scene") }
        XCTAssertEqual(first.name, "First")
        guard case .transition(let trans) = storyboard.steps[1] else { return XCTFail("Expected transition") }
        XCTAssertEqual(trans.style, .crossfade)
        XCTAssertEqual(trans.frames, 1)
        guard case .scene(let second) = storyboard.steps[2] else { return XCTFail("Expected scene") }
        XCTAssertEqual(second.name, "Second")
    }

    func testParsesTweenTransitionDefaultsToOneFrame() throws {
        let text = """
        Scene: Start
        Transition: tween
        Scene: End
        """
        let storyboard = try StoryboardParser.parse(text)
        XCTAssertEqual(storyboard.steps.count, 3)
        guard case .transition(let trans) = storyboard.steps[1] else { return XCTFail("Expected transition") }
        XCTAssertEqual(trans.style, .tween)
        XCTAssertEqual(trans.frames, 1)
    }

    func testThrowsOnUnknownLines() {
        let text = """
        Scene: One
        Unknown: foo
        Scene: Two
        """
        XCTAssertThrowsError(try StoryboardParser.parse(text)) { error in
            guard let parseError = error as? ParserError else { return XCTFail("Expected ParserError") }
            XCTAssertEqual(parseError.line, 2)
            XCTAssertTrue(parseError.message.contains("Unexpected line"))
        }
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
