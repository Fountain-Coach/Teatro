import XCTest
@testable import Teatro

final class AnimatorTests: XCTestCase {
    func testRenderFramesCreatesFiles() async {
        struct Dummy: Renderable {
            func render() -> String { "Hello" }
        }
        let base = "test_frame"
        let fileManager = FileManager.default
        let check: (Int) -> String = { index in
            let png = "Animations/\(base)_\(index).png"
            if fileManager.fileExists(atPath: png) { return png }
            return "Animations/\(base)_\(index).svg"
        }
        for i in 0..<2 {
            let path = check(i)
            if fileManager.fileExists(atPath: path) {
                try? fileManager.removeItem(atPath: path)
            }
        }

        await Animator.renderFrames([Dummy(), Dummy()], baseName: base)

        for i in 0..<2 {
            let path = check(i)
            XCTAssertTrue(fileManager.fileExists(atPath: path))
            try? fileManager.removeItem(atPath: path)
        }
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
