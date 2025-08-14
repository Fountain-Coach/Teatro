import XCTest
@testable import Teatro

final class FlexEnvelopeTests: XCTestCase {
    func testJSONRoundTrip() throws {
        let json = """
        {"v":1,"ts":123,"corr":"abc","intent":"test","body":{"foo":"bar","num":5}}
        """.data(using: .utf8)!
        let env = try JSONDecoder().decode(FlexEnvelope.self, from: json)
        XCTAssertEqual(env.v, 1)
        XCTAssertEqual(env.ts, 123)
        XCTAssertEqual(env.corr, "abc")
        XCTAssertEqual(env.intent, "test")
        XCTAssertEqual(env.body["foo"]?.value as? String, "bar")
        XCTAssertEqual(env.body["num"]?.value as? Int, 5)
        let encoded = try JSONEncoder().encode(env)
        let decoded = try JSONDecoder().decode(FlexEnvelope.self, from: encoded)
        XCTAssertEqual(decoded.corr, "abc")
        XCTAssertEqual(decoded.body["foo"]?.value as? String, "bar")
    }
}
