import XCTest
import MIDI2
@testable import Teatro

final class UMPEncoderEventTests: XCTestCase {
    func testEncodeNoteOnEvent() throws {
        let bytes: [UInt8] = [0x20, 0x90, 0x3C, 0x40]
        let events = try UMPParser.parse(data: Data(bytes))
        let words = UMPEncoder.encodeEvents(events)
        XCTAssertEqual(words, [0x20903C40])
    }

    func testEncodeNoteWithPerNoteControllerAndAttributeRoundTrip() throws {
        let events: [any MidiEventProtocol] = [
            JRTimestampEvent(timestamp: 0, group: nil, value: 0x00000001),
            PerNoteControllerEvent(timestamp: 0x00000001, group: 0, channel: 0, noteNumber: 60, controllerIndex: 0x02, controllerValue: 0x0A0B0C0D),
            NoteOnWithAttributeEvent(timestamp: 0x00000001, group: 0, channel: 0, noteNumber: 60, velocity: 0x01020304, attributeType: 0x02, attributeData: 0x3344)
        ]
        let encoded = UMPEncoder.encodeEvents(events)
        let expected: [UInt32] = [
            0x10000001,
            0x40003C02, 0x0A0B0C0D,
            0x40903C02, 0x01023344
        ]
        XCTAssertEqual(encoded, expected)
        var bytes: [UInt8] = []
        for w in encoded {
            bytes.append(UInt8((w >> 24) & 0xFF))
            bytes.append(UInt8((w >> 16) & 0xFF))
            bytes.append(UInt8((w >> 8) & 0xFF))
            bytes.append(UInt8(w & 0xFF))
        }
        let parsed = try UMPParser.parse(data: Data(bytes))
        XCTAssertEqual(parsed.count, 3)
        guard let _ = parsed[0] as? JRTimestampEvent,
              let ctrl = parsed[1] as? PerNoteControllerEvent,
              let noteOn = parsed[2] as? NoteOnWithAttributeEvent else {
            return XCTFail("Unexpected event types")
        }
        XCTAssertEqual(ctrl.timestamp, 0x00000001)
        XCTAssertEqual(noteOn.attributeData, 0x3344)
        XCTAssertEqual(noteOn.velocity, 0x01020000)
        let roundTrip = UMPEncoder.encodeEvents(parsed)
        XCTAssertEqual(roundTrip, expected)
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
