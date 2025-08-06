import XCTest
@testable import Teatro

final class UMPEncoderEventTests: XCTestCase {
    func testEncodeNoteOnEvent() throws {
        let bytes: [UInt8] = [0x20, 0x90, 0x3C, 0x40]
        let events = try UMPParser.parse(data: Data(bytes))
        let words = UMPEncoder.encodeEvents(events)
        XCTAssertEqual(words, [0x20903C40])
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
