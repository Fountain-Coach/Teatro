import XCTest
@testable import Teatro

final class MIDI1BridgeTests: XCTestCase {
    func testRoundTripConversion() throws {
        let event = ChannelVoiceEvent(timestamp: 0, type: .noteOn, group: 0, channel: 0, noteNumber: 60, velocity: 100, controllerValue: nil)
        let words = UMPEncoder.encodeEvents([event])
        var umpData = Data()
        for word in words {
            var be = word.bigEndian
            withUnsafeBytes(of: &be) { umpData.append(contentsOf: $0) }
        }
        let midi1 = try MIDI1Bridge.umpToMIDI1(umpData)
        let roundTripWords = MIDI1Bridge.midi1ToUMP(midi1)
        var roundTripData = Data()
        for word in roundTripWords {
            var be = word.bigEndian
            withUnsafeBytes(of: &be) { roundTripData.append(contentsOf: $0) }
        }
        let parsed = try UMPParser.parse(data: roundTripData)
        guard let note = parsed.first as? ChannelVoiceEvent else {
            return XCTFail("Expected ChannelVoiceEvent")
        }
        XCTAssertEqual(note.noteNumber, 60)
        XCTAssertEqual(note.velocity, 100)
    }

    func testUnsupportedMessagesGraceful() throws {
        let umpBytes: [UInt8] = [0x00, 0x00, 0x00, 0x00]
        let midi1 = try MIDI1Bridge.umpToMIDI1(Data(umpBytes))
        XCTAssertTrue(midi1.isEmpty)
        let words = MIDI1Bridge.midi1ToUMP(Data([0xF2, 0x01, 0x02]))
        XCTAssertTrue(words.isEmpty)
    }

    func testRunningStatusConversion() throws {
        let midi1 = Data([0x90, 0x40, 0x7F, 0x41, 0x7F])
        let words = MIDI1Bridge.midi1ToUMP(midi1)
        XCTAssertEqual(words.count, 2)
        var data = Data()
        for word in words {
            var be = word.bigEndian
            withUnsafeBytes(of: &be) { data.append(contentsOf: $0) }
        }
        let events = try UMPParser.parse(data: data)
        XCTAssertEqual(events.count, 2)
    }

    func testPitchBendEdgeConversion() throws {
        let midi1 = Data([0xE0, 0x00, 0x00, 0xE0, 0x7F, 0x7F])
        let words = MIDI1Bridge.midi1ToUMP(midi1)
        var data = Data()
        for word in words {
            var be = word.bigEndian
            withUnsafeBytes(of: &be) { data.append(contentsOf: $0) }
        }
        let roundTrip = try MIDI1Bridge.umpToMIDI1(data)
        let bytes = [UInt8](roundTrip)
        XCTAssertEqual(bytes.count, 6)
        XCTAssertEqual(Array(bytes[0...2]), [0xE0, 0x00, 0x00])
        XCTAssertEqual(Array(bytes[3...5]), [0xE0, 0x00, 0x00])
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
