import XCTest
@testable import Teatro

// Tests required by teatro-root agent policy to ensure SSE envelopes round-trip.

final class FountainSSEEnvelopeTests: XCTestCase {
    func testJSONRoundTrip() throws {
        let env = FountainSSEEnvelope(
            ev: .message,
            id: "abc",
            ct: "text/plain",
            seq: 42,
            frag: .init(i: 0, n: 1),
            ts: 1.23,
            data: "hello".data(using: .utf8)
        )
        let encoded = try env.encodeJSON()
        let decoded = try FountainSSEEnvelope.decodeJSON(encoded)
        XCTAssertEqual(decoded, env)
    }

    func testCBORRoundTrip() throws {
        let env = FountainSSEEnvelope(
            ev: .ctrl,
            seq: 7,
            data: "{\"ack\":1}".data(using: .utf8)
        )
        let encoded = try env.encodeCBOR()
        let decoded = try FountainSSEEnvelope.decodeCBOR(encoded)
        XCTAssertEqual(decoded, env)
    }

    func testInvalidEventRejected() throws {
        let json = """
        {"v":1,"ev":"bogus","seq":1}
        """.data(using: .utf8)!
        XCTAssertThrowsError(try FountainSSEEnvelope.decodeJSON(json))
    }

    func testInvalidVersionRejected() throws {
        let json = """
        {"v":2,"ev":"message","seq":1}
        """.data(using: .utf8)!
        XCTAssertThrowsError(try FountainSSEEnvelope.decodeJSON(json))
    }
}
