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
        XCTAssertEqual(event.velocity, 0xFFFF0000)
        XCTAssertEqual(MIDI.midi1Velocity(from: event.velocity ?? 0), 0x7F)
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
        XCTAssertEqual(event.controllerValue, 0xFFFFFFFF)
        XCTAssertEqual(MIDI.midi1Controller(from: event.controllerValue ?? 0), 0x7F)
    }

    func testNormalizeControllerFunction() {
        let value: UInt32 = 0x12345678
        let normalized = MIDI.midi1Controller(from: value)
        XCTAssertEqual(normalized, 0x09)
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
