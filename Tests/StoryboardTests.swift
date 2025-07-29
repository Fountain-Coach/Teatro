import XCTest
@testable import Teatro

final class StoryboardTests: XCTestCase {
    func testStoryboardFrameGeneration() {
        let sb = Storyboard {
            Scene("Intro") {
                Text("A")
            }
            Transition(style: .crossfade, frames: 2)
            Scene("Next") {
                Text("B")
            }
        }
        let frames = sb.frames()
        XCTAssertEqual(frames.count, 4)
        XCTAssertEqual(frames.first?.render(), "A")
        XCTAssertEqual(frames.last?.render(), "B")
    }

    func testCodexPromptContainsFrames() {
        let sb = Storyboard {
            Scene("Only") { Text("X") }
        }
        let prompt = CodexStoryboardPreviewer.prompt(sb)
        XCTAssertTrue(prompt.contains("Frames: 1"))
        XCTAssertTrue(prompt.contains("X"))
    }
}
