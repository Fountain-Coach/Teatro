import XCTest
@testable import Teatro

final class BasicRenderableTests: XCTestCase {
    func testSimpleRenderablesProduceOutput() {
        let text = Text("Hello")
        XCTAssertFalse(text.render().isEmpty)

        let stack = VStack {
            Text("A")
            Text("B")
        }
        XCTAssertFalse(stack.render().isEmpty)
    }
}
