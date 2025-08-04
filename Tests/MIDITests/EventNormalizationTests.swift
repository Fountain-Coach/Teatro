import XCTest
@testable import Teatro

final class EventNormalizationTests: XCTestCase {
    func testVelocityNormalization() throws {
        let bytes: [UInt8] = [
            0x40, 0x90, 0x3C, 0x00,
            0xFF, 0xFF, 0x00, 0x00
        ]
        let events = try UMPParser.parse(data: Data(bytes))
        guard let event = events.first as? ChannelVoiceEvent else {
            return XCTFail("Expected ChannelVoiceEvent")
        }
        XCTAssertEqual(event.velocity, 0xFF)
    }

    func testControllerNormalization() throws {
        let bytes: [UInt8] = [
            0x40, 0xB0, 0x07, 0x00,
            0xFF, 0xFF, 0xFF, 0xFF
        ]
        let events = try UMPParser.parse(data: Data(bytes))
        guard let event = events.first as? ChannelVoiceEvent else {
            return XCTFail("Expected ChannelVoiceEvent")
        }
        XCTAssertEqual(event.controllerValue, UInt32(0xFF))
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
