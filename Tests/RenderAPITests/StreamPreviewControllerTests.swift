import XCTest
@testable import RenderAPI
import Teatro

/// Integration test verifying that UMP fragments are translated into a token stream.
final class StreamPreviewControllerTests: XCTestCase {
    func testTokenAccumulation() async throws {
        let controller = StreamPreviewController()
        let env1 = FountainSSEEnvelope(ev: .message, seq: 1, data: "Hello")
        let env2 = FountainSSEEnvelope(ev: .message, seq: 2, data: "World")
        try await controller.ingestFlex(env1.encodeJSON())
        try await controller.ingestFlex(env2.encodeJSON())
        try await Task.sleep(nanoseconds: 50_000_000)
        let tokens = await controller.tokens()
        XCTAssertEqual(tokens, ["Hello", "World"])
    }
}
