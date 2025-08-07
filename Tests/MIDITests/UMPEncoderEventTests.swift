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
        var bytes: [UInt8] = []
        for w in encoded {
            bytes.append(UInt8((w >> 24) & 0xFF))
            bytes.append(UInt8((w >> 16) & 0xFF))
            bytes.append(UInt8((w >> 8) & 0xFF))
            bytes.append(UInt8(w & 0xFF))
        }
        let events = try UMPParser.parse(data: Data(bytes))
        let roundTrip = UMPEncoder.encodeEvents(events)
        XCTAssertEqual(encoded, roundTrip)
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
