import XCTest
import MIDI2
@testable import Teatro

final class MIDI2Tests: XCTestCase {
    func testUMPEncoderProducesWords() {
        let vel = UInt16((MIDI.fromUnitFloat(0.5) >> 16) & 0xFFFF)
        let note = Midi2NoteOn(group: Uint4(0)!, channel: Uint4(0)!, note: Uint7(60)!, velocity: vel)
        let packets = UMPEncoder.encode(note)
        XCTAssertEqual(packets, [0x40903C00, 0x7FFF0000])
    }

    func testCSDRendererWritesFile() throws {
        let score = CsoundScore(orchestra: "f 1 0 0 10 1", score: "i1 0 1 0.5")
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("csd")
        CSDRenderer.renderToFile(score, to: url.path)
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
    }

    func test32BitVelocityParsingFromFixture() throws {
        let fixtures = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Fixtures")
        let jsonData = try Data(contentsOf: fixtures.appendingPathComponent("ump_packets.json"))
        let object = try JSONSerialization.jsonObject(with: jsonData) as? [String: [NSNumber]]
        guard let bytes = object?["noteOn32Velocity"]?.map({ UInt8(truncating: $0) }) else {
            return XCTFail("Missing fixture")
        }
        let events = try UMPParser.parse(data: Data(bytes))
        guard let event = events.first as? NoteOnWithAttributeEvent else {
            return XCTFail("Expected NoteOnWithAttributeEvent")
        }
        XCTAssertEqual(event.velocity, 0x12340000)
        XCTAssertEqual(event.attributeType.rawValue, 0x00)
        XCTAssertEqual(event.attributeData, 0x5678)
    }

    func testPerNoteControllerParsingFromFixture() throws {
        let fixtures = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Fixtures")
        let jsonData = try Data(contentsOf: fixtures.appendingPathComponent("ump_packets.json"))
        let object = try JSONSerialization.jsonObject(with: jsonData) as? [String: [NSNumber]]
        guard let bytes = object?["perNoteController"]?.map({ UInt8(truncating: $0) }) else {
            return XCTFail("Missing fixture")
        }
        let events = try UMPParser.parse(data: Data(bytes))
        guard let event = events.first as? PerNoteControllerEvent else {
            return XCTFail("Expected PerNoteControllerEvent")
        }
        XCTAssertEqual(event.controllerIndex, 0x01)
        XCTAssertEqual(event.controllerValue, 0x01020304)
    }

    func testJRTimestampParsingFromFixture() throws {
        let fixtures = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Fixtures")
        let jsonData = try Data(contentsOf: fixtures.appendingPathComponent("ump_packets.json"))
        let object = try JSONSerialization.jsonObject(with: jsonData) as? [String: [NSNumber]]
        guard let bytes = object?["jrTimestamp"]?.map({ UInt8(truncating: $0) }) else {
            return XCTFail("Missing fixture")
        }
        let events = try UMPParser.parse(data: Data(bytes))
        guard let event = events.first as? JRTimestampEvent else {
            return XCTFail("Expected JRTimestampEvent")
        }
        XCTAssertEqual(event.value, 0x00000001)
    }

    // MARK: - Spec fixture round-trips

    /// Helper converting 32-bit words into raw bytes
    private func bytes(from words: [UInt32]) -> [UInt8] {
        var out: [UInt8] = []
        for w in words {
            out.append(UInt8((w >> 24) & 0xFF))
            out.append(UInt8((w >> 16) & 0xFF))
            out.append(UInt8((w >> 8) & 0xFF))
            out.append(UInt8(w & 0xFF))
        }
        return out
    }

    func testRoundTripNoteOnWithAttributeFromSpec() throws {
        let words: [UInt32] = [0x40903C02, 0x12345678]
        let events = try UMPParser.parse(data: Data(bytes(from: words)))
        guard let event = events.first as? NoteOnWithAttributeEvent else {
            return XCTFail("Expected NoteOnWithAttributeEvent")
        }
        XCTAssertEqual(event.noteNumber, 0x3C)
        XCTAssertEqual(event.attributeType, .profileSpecific)
        XCTAssertEqual(event.attributeData, 0x5678)
        XCTAssertEqual(event.velocity, 0x12340000)
        let encoded = UMPEncoder.encodeEvents(events)
        XCTAssertEqual(encoded, words)
    }

    func testRoundTripPitchClampReleaseFromSpec() throws {
        let words: [UInt32] = [
            0x40103C00, 0x21234567,
            0x40103C00, 0x30000000
        ]
        let events = try UMPParser.parse(data: Data(bytes(from: words)))
        XCTAssertEqual(events.count, 2)
        guard let clamp = events.first as? PitchClampEvent,
              let release = events.last as? PitchReleaseEvent else {
            return XCTFail("Expected PitchClampEvent then PitchReleaseEvent")
        }
        XCTAssertEqual(clamp.noteNumber, 0x3C)
        XCTAssertEqual(clamp.pitch, 0x01234567)
        XCTAssertEqual(release.noteNumber, 0x3C)
        let encoded = UMPEncoder.encodeEvents(events)
        XCTAssertEqual(encoded, words)
    }

    func testRoundTripNoteEndFromSpec() throws {
        let words: [UInt32] = [0x40103C00, 0x01234567]
        let events = try UMPParser.parse(data: Data(bytes(from: words)))
        guard let end = events.first as? NoteEndEvent else {
            return XCTFail("Expected NoteEndEvent")
        }
        XCTAssertEqual(end.noteNumber, 0x3C)
        XCTAssertEqual(end.velocity, 0x01230000)
        XCTAssertEqual(end.attributeData, 0x4567)
        let encoded = UMPEncoder.encodeEvents(events)
        XCTAssertEqual(encoded, words)
    }

    func testRoundTripPerNotePitchBendFromSpec() throws {
        let words: [UInt32] = [0x40203C00, 0x12345678]
        let events = try UMPParser.parse(data: Data(bytes(from: words)))
        guard let bend = events.first as? PerNotePitchBendEvent else {
            return XCTFail("Expected PerNotePitchBendEvent")
        }
        XCTAssertEqual(bend.noteNumber, 0x3C)
        XCTAssertEqual(bend.pitch, 0x12345678)
        let encoded = UMPEncoder.encodeEvents(events)
        XCTAssertEqual(encoded, words)
    }

    func testRoundTripRPNFromSpec() throws {
        let words: [UInt32] = [0x40600223, 0x11223344]
        let events = try UMPParser.parse(data: Data(bytes(from: words)))
        guard let rpn = events.first as? RegisteredParameterNumber else {
            return XCTFail("Expected RegisteredParameterNumber")
        }
        XCTAssertEqual(rpn.parameter, 0x0123)
        XCTAssertEqual(rpn.value, 0x11223344)
        let encoded = UMPEncoder.encodeEvents(events)
        XCTAssertEqual(encoded, words)
    }

    func testRoundTripNRPNFromSpec() throws {
        let words: [UInt32] = [0x40700223, 0x55667788]
        let events = try UMPParser.parse(data: Data(bytes(from: words)))
        guard let nrpn = events.first as? NonRegisteredParameterNumber else {
            return XCTFail("Expected NonRegisteredParameterNumber")
        }
        XCTAssertEqual(nrpn.parameter, 0x0123)
        XCTAssertEqual(nrpn.value, 0x55667788)
        let encoded = UMPEncoder.encodeEvents(events)
        XCTAssertEqual(encoded, words)
    }

    func testCompleteNoteLifecycleSequence() throws {
        let words: [UInt32] = [
            0x40903C02, 0x12345678, // Note On with attribute
            0x40103C00, 0x21234567, // Pitch Clamp
            0x40103C00, 0x30000000, // Pitch Release
            0x40803C02, 0x87654321, // Note Off with attribute
            0x40103C00, 0x01234567  // Note End
        ]
        let events = try UMPParser.parse(data: Data(bytes(from: words)))
        XCTAssertEqual(events.count, 5)
        guard let on = events[0] as? NoteOnWithAttributeEvent,
              let clamp = events[1] as? PitchClampEvent,
              let release = events[2] as? PitchReleaseEvent,
              let off = events[3] as? NoteOffWithAttributeEvent,
              let end = events[4] as? NoteEndEvent else {
            return XCTFail("Expected full note lifecycle events")
        }
        XCTAssertEqual(on.attributeType, .profileSpecific)
        XCTAssertEqual(clamp.pitch, 0x01234567)
        XCTAssertEqual(release.noteNumber, 0x3C)
        XCTAssertEqual(off.attributeData, 0x4321)
        XCTAssertEqual(end.attributeData, 0x4567)
        let encoded = UMPEncoder.encodeEvents(events)
        XCTAssertEqual(encoded, words)
    }

    // MARK: - Negative cases

    func testMalformedNoteManagementMissingWordThrows() {
        let bytes: [UInt8] = [0x40, 0x10, 0x3C, 0x00]
        XCTAssertThrowsError(try UMPParser.parse(data: Data(bytes))) { error in
            guard case UMPParserError.truncated = error else {
                return XCTFail("Expected truncated error")
            }
        }
    }

    func testTruncatedNoteOnWithAttributeThrows() {
        let bytes: [UInt8] = [0x40, 0x90, 0x3C, 0x02]
        XCTAssertThrowsError(try UMPParser.parse(data: Data(bytes))) { error in
            guard case UMPParserError.truncated = error else {
                return XCTFail("Expected truncated error")
            }
        }
    }

    func testTruncatedNoteOffWithAttributeThrows() {
        let bytes: [UInt8] = [0x40, 0x80, 0x3C, 0x02]
        XCTAssertThrowsError(try UMPParser.parse(data: Data(bytes))) { error in
            guard case UMPParserError.truncated = error else {
                return XCTFail("Expected truncated error")
            }
        }
    }

    func testInvalidNoteManagementSubtypeReturnsUnknown() throws {
        let words: [UInt32] = [0x40103C00, 0x10000000]
        let events = try UMPParser.parse(data: Data(bytes(from: words)))
        XCTAssertTrue(events.first is UnknownEvent)
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
