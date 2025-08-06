import XCTest
@testable import Teatro

final class DispatcherPromptTests: XCTestCase {
    func testInitAndRender() {
        let prompt = DispatcherPrompt()
        let output = prompt.render()
        XCTAssertTrue(output.contains("Dispatcher"))
        XCTAssertTrue(output.contains("<content>"))
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
