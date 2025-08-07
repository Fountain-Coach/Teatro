import XCTest
@testable import Teatro

final class UMPEncoderEventTests: XCTestCase {
    func testEncodeNoteOnEvent() throws {
        let bytes: [UInt8] = [0x20, 0x90, 0x3C, 0x40]
        let events = try UMPParser.parse(data: Data(bytes))
        let words = UMPEncoder.encodeEvents(events)
        XCTAssertEqual(words, [0x20903C40])
    }

    func testEncodeNoteWithPerNoteControllerAndAttributeRoundTrip() throws {
        let note = MIDI2Note(
            channel: 0,
            note: 60,
            velocity: 0x01020304,
            duration: 0.1,
            perNoteControllers: [PerNoteController(index: 0x02, value: 0x0A0B0C0D)],
            jrTimestamp: 0x00000001,
            attributes: [.profileSpecific: 0x11223344]
        )
        let encoded = UMPEncoder.encode(note)
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
        let events = try UMPParser.parse(data: Data(bytes))
        XCTAssertEqual(events.count, 3)
        guard let _ = events[0] as? JRTimestampEvent,
              let ctrl = events[1] as? PerNoteControllerEvent,
              let noteOn = events[2] as? NoteOnWithAttributeEvent else {
            return XCTFail("Unexpected event types")
        }
        XCTAssertEqual(ctrl.timestamp, 0x00000001)
        XCTAssertEqual(noteOn.attributeData, 0x3344)
        XCTAssertEqual(noteOn.velocity, 0x01020000)
        let roundTrip = UMPEncoder.encodeEvents(events)
        XCTAssertEqual(roundTrip, expected)
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
