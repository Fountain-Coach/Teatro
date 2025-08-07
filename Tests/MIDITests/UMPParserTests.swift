import XCTest
@testable import Teatro

final class UMPParserTests: XCTestCase {
    func testUtilityMessageDecoding() throws {
        let bytes: [UInt8] = [0x02, 0x7F, 0xAA, 0xBB]
        let events = try UMPParser.parse(data: Data(bytes))
        guard let event = events.first as? UnknownEvent else {
            return XCTFail("Expected UnknownEvent")
        }
        XCTAssertEqual(event.rawData, Data(bytes))
    }

    func testMIDI1ChannelVoiceDecoding() throws {
        let bytes: [UInt8] = [0x20, 0x90, 0x3C, 0x40]
        let events = try UMPParser.parse(data: Data(bytes))
        guard let event = events.first as? ChannelVoiceEvent else {
            return XCTFail("Expected ChannelVoiceEvent")
        }
        XCTAssertEqual(event.channel, 0)
        XCTAssertEqual(event.type, .noteOn)
        XCTAssertEqual(event.noteNumber, 0x3C)
        XCTAssertEqual(event.velocity, 0x40)
    }

    func testMIDI1NoteOnZeroVelocityTreatedAsNoteOff() throws {
        let bytes: [UInt8] = [0x20, 0x90, 0x3C, 0x00]
        let events = try UMPParser.parse(data: Data(bytes))
        guard let event = events.first as? ChannelVoiceEvent else {
            return XCTFail("Expected ChannelVoiceEvent")
        }
        XCTAssertEqual(event.type, .noteOff)
        XCTAssertEqual(event.noteNumber, 0x3C)
        XCTAssertEqual(event.velocity, 0)
    }

    func testSystemMessageDecoding() throws {
        let bytes: [UInt8] = [0x12, 0xF8, 0x00, 0x00]
        let events = try UMPParser.parse(data: Data(bytes))
        guard let event = events.first as? JRTimestampEvent else {
            return XCTFail("Expected JRTimestampEvent")
        }
        XCTAssertEqual(event.value, 0x00F80000)
    }

    func testMIDI2ChannelVoiceDecoding() throws {
        let bytes: [UInt8] = [
            0x40, 0x90, 0x3C, 0x00,
            0x7F, 0x00, 0x00, 0x00
        ]
        let events = try UMPParser.parse(data: Data(bytes))
        guard let event = events.first as? ChannelVoiceEvent else {
            return XCTFail("Expected ChannelVoiceEvent")
        }
        XCTAssertEqual(event.channel, 0)
        XCTAssertEqual(event.type, .noteOn)
        XCTAssertEqual(event.noteNumber, 0x3C)
        XCTAssertEqual(MIDI.midi1Velocity(from: event.velocity ?? 0), 0x7F)
    }

    func testMIDI2NoteOnZeroVelocityTreatedAsNoteOff() throws {
        let bytes: [UInt8] = [
            0x40, 0x90, 0x3C, 0x00,
            0x00, 0x00, 0x00, 0x00
        ]
        let events = try UMPParser.parse(data: Data(bytes))
        guard let event = events.first as? ChannelVoiceEvent else {
            return XCTFail("Expected ChannelVoiceEvent")
        }
        XCTAssertEqual(event.type, .noteOff)
        XCTAssertEqual(event.noteNumber, 0x3C)
        XCTAssertEqual(event.velocity, 0x00)
    }

    func testMIDI2ProgramChangeDecoding() throws {
        let bytes: [UInt8] = [
            0x40, 0xC0, 0x00, 0x00,
            0x05, 0x00, 0x00, 0x00
        ]
        let events = try UMPParser.parse(data: Data(bytes))
        guard let event = events.first as? ChannelVoiceEvent else {
            return XCTFail("Expected ChannelVoiceEvent")
        }
        XCTAssertEqual(event.type, .programChange)
        XCTAssertEqual(event.channel, 0)
        XCTAssertEqual(event.controllerValue, 0x05)
    }

    func testMIDI2PitchBendDecoding() throws {
        let bytes: [UInt8] = [
            0x40, 0xE0, 0x00, 0x00,
            0x00, 0x01, 0x00, 0x00
        ]
        let events = try UMPParser.parse(data: Data(bytes))
        guard let event = events.first as? ChannelVoiceEvent else {
            return XCTFail("Expected ChannelVoiceEvent")
        }
        XCTAssertEqual(event.type, .pitchBend)
        XCTAssertEqual(event.channel, 0)
        XCTAssertEqual(event.controllerValue, 0x00010000)
    }

    func testChannelPressureDecoding() throws {
        let midi1: [UInt8] = [0x20, 0xD0, 0x40, 0x00]
        let midi2: [UInt8] = [
            0x40, 0xD0, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x80
        ]
        let events1 = try UMPParser.parse(data: Data(midi1))
        let events2 = try UMPParser.parse(data: Data(midi2))
        guard let e1 = events1.first as? ChannelVoiceEvent,
              let e2 = events2.first as? ChannelVoiceEvent else {
            return XCTFail("Expected ChannelVoiceEvent")
        }
        XCTAssertEqual(e1.type, .channelPressure)
        XCTAssertEqual(e1.controllerValue, 0x40)
        XCTAssertEqual(e2.type, .channelPressure)
        XCTAssertEqual(e2.controllerValue, 0x00000080)
    }

    func testPolyphonicKeyPressureDecoding() throws {
        let midi1: [UInt8] = [0x20, 0xA0, 0x3C, 0x40]
        let midi2: [UInt8] = [
            0x40, 0xA0, 0x3C, 0x00,
            0x40, 0x00, 0x00, 0x00
        ]
        let events1 = try UMPParser.parse(data: Data(midi1))
        let events2 = try UMPParser.parse(data: Data(midi2))
        guard let e1 = events1.first as? ChannelVoiceEvent,
              let e2 = events2.first as? ChannelVoiceEvent else {
            return XCTFail("Expected ChannelVoiceEvent")
        }
        XCTAssertEqual(e1.type, .polyphonicKeyPressure)
        XCTAssertEqual(e1.noteNumber, 0x3C)
        XCTAssertEqual(e1.velocity, 0x40)
        XCTAssertEqual(e2.type, .polyphonicKeyPressure)
        XCTAssertEqual(e2.noteNumber, 0x3C)
        XCTAssertEqual(MIDI.midi1Velocity(from: e2.velocity ?? 0), 0x40)
    }

    func testControlChangeDecoding() throws {
        let midi1: [UInt8] = [0x20, 0xB0, 0x07, 0x40]
        let midi2: [UInt8] = [
            0x40, 0xB0, 0x07, 0x00,
            0x40, 0x00, 0x00, 0x00
        ]
        let events1 = try UMPParser.parse(data: Data(midi1))
        let events2 = try UMPParser.parse(data: Data(midi2))
        guard let e1 = events1.first as? ChannelVoiceEvent,
              let e2 = events2.first as? ChannelVoiceEvent else {
            return XCTFail("Expected ChannelVoiceEvent")
        }
        XCTAssertEqual(e1.type, .controlChange)
        XCTAssertEqual(e1.noteNumber, 0x07)
        XCTAssertEqual(e1.controllerValue, 0x40)
        XCTAssertEqual(e2.type, .controlChange)
        XCTAssertEqual(e2.noteNumber, 0x07)
        XCTAssertEqual(MIDI.midi1Controller(from: e2.controllerValue ?? 0), 0x40)
    }

    func testSysEx7Decoding() throws {
        let bytes: [UInt8] = [
            0x50, 0x00, 0x12, 0x34,
            0x56, 0x78, 0x9A, 0xBC
        ]
        let events = try UMPParser.parse(data: Data(bytes))
        guard let event = events.first as? SysExEvent else {
            return XCTFail("Expected SysExEvent")
        }
        XCTAssertEqual(event.rawData, Data(bytes))
    }

    func testSysEx8Decoding() throws {
        let bytes: [UInt8] = [
            0x60, 0x00, 0x12, 0x34,
            0x56, 0x78, 0x9A, 0xBC,
            0xDE, 0xF0, 0x00, 0x00
        ]
        let events = try UMPParser.parse(data: Data(bytes))
        guard let event = events.first as? SysExEvent else {
            return XCTFail("Expected SysExEvent")
        }
        XCTAssertEqual(event.rawData, Data(bytes))
    }

    func testGroupChannelMapping() throws {
        // Group 2, channel 10 should remain separate
        let bytes: [UInt8] = [0x22, 0x9A, 0x3C, 0x40]
        let events = try UMPParser.parse(data: Data(bytes))
        guard let event = events.first as? ChannelVoiceEvent else {
            return XCTFail("Expected ChannelVoiceEvent")
        }
        XCTAssertEqual(event.group, 0x2)
        XCTAssertEqual(event.channel, 0xA)
    }

    func testUnknownPacketPreserved() throws {
        let bytes: [UInt8] = [
            0x70, 0x00, 0x00, 0x00,
            0x01, 0x02, 0x03, 0x04,
            0x05, 0x06, 0x07, 0x08,
            0x09, 0x0A, 0x0B, 0x0C
        ]
        let events = try UMPParser.parse(data: Data(bytes))
        guard let event = events.first as? UnknownEvent else {
            return XCTFail("Expected UnknownEvent")
        }
        XCTAssertEqual(event.rawData, Data(bytes))
    }

    func testRoundTripPerNoteControllerAndAttribute() throws {
        let words: [UInt32] = [
            0x10000001,
            0x40003C02, 0x0A0B0C0D,
            0x40903C01, 0x03043344
        ]
        var bytes: [UInt8] = []
        for w in words {
            bytes.append(UInt8((w >> 24) & 0xFF))
            bytes.append(UInt8((w >> 16) & 0xFF))
            bytes.append(UInt8((w >> 8) & 0xFF))
            bytes.append(UInt8(w & 0xFF))
        }
        let events = try UMPParser.parse(data: Data(bytes))
        XCTAssertEqual(events.count, 3)
        let encoded = UMPEncoder.encodeEvents(events)
        XCTAssertEqual(encoded, words)
    }

    func testMisalignedDataThrows() {
        let bytes: [UInt8] = [0x00]
        XCTAssertThrowsError(try UMPParser.parse(data: Data(bytes))) { error in
            guard case UMPParserError.misaligned = error else {
                return XCTFail("Expected misaligned error")
            }
        }
    }

    func testTruncatedPacketThrows() {
        // Message type 0x4 requires two words but only one is provided
        let bytes: [UInt8] = [0x40, 0x90, 0x3C, 0x00]
        XCTAssertThrowsError(try UMPParser.parse(data: Data(bytes))) { error in
            guard case UMPParserError.truncated = error else {
                return XCTFail("Expected truncated error")
            }
        }
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
