import XCTest
@testable import Teatro

final class StoryboardDSLTests: XCTestCase {
    func testStoryboardBuilderCreatesSteps() {
        let storyboard = Storyboard {
            Scene("First") { Text("A") }
            Transition(style: .crossfade, frames: 1)
            Scene("Second") { Text("B") }
        }
        XCTAssertEqual(storyboard.steps.count, 3)
    }

    func testFramesGenerationMatchesScenesAndTransitions() {
        let storyboard = Storyboard {
            Scene("Start") { Text("A") }
            Transition(style: .crossfade, frames: 1)
            Scene("End") { Text("B") }
        }
        let frames = storyboard.frames()
        XCTAssertEqual(frames.count, 3)
        XCTAssertEqual(frames[0].render(), "A")
        XCTAssertEqual(frames[1].render(), "A")
        XCTAssertEqual(frames[2].render(), "B")
    }
}
