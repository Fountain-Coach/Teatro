import Foundation
import XCTest
@testable import Teatro

final class MidiFileParserTests: XCTestCase {
    func testHeaderParsing() throws {
        let bytes: [UInt8] = [
            0x4D, 0x54, 0x68, 0x64, // 'MThd'
            0x00, 0x00, 0x00, 0x06, // length
            0x00, 0x01,             // format 1
            0x00, 0x02,             // track count 2
            0x01, 0xE0              // division 480
        ]
        let data = Data(bytes)
        let header = try MidiFileParser.parseHeader(data: data)
        XCTAssertEqual(header.format, 1)
        XCTAssertEqual(header.trackCount, 2)
        XCTAssertEqual(header.division, 480)
    }

    func testTrackParsing() throws {
        let bytes: [UInt8] = [
            0x4D, 0x54, 0x72, 0x6B, // 'MTrk'
            0x00, 0x00, 0x00, 0x24, // length 36
            // 0 delta, meta track name "Test"
            0x00, 0xFF, 0x03, 0x04, 0x54, 0x65, 0x73, 0x74,
            // 0 delta, tempo 120 BPM (500000 microseconds per quarter)
            0x00, 0xFF, 0x51, 0x03, 0x07, 0xA1, 0x20,
            // 0 delta, time signature 4/4
            0x00, 0xFF, 0x58, 0x04, 0x04, 0x02, 0x18, 0x08,
            // 0 delta, note on C4 velocity 64
            0x00, 0x90, 0x3C, 0x40,
            // 480 delta, note off
            0x83, 0x60, 0x80, 0x3C, 0x40,
            // 0 delta, end of track
            0x00, 0xFF, 0x2F, 0x00
        ]
        let data = Data(bytes)
        let events = try MidiFileParser.parseTrack(data: data)
        XCTAssertEqual(events.count, 6)
        if let meta = events[0] as? MetaEvent, let data = meta.rawData {
            XCTAssertEqual(meta.timestamp, 0)
            XCTAssertEqual(meta.metaType, 0x03)
            XCTAssertEqual(String(data: data, encoding: .ascii), "Test")
        } else {
            XCTFail("Expected MetaEvent track name")
        }
        if let meta = events[1] as? MetaEvent, let data = meta.rawData {
            XCTAssertEqual(meta.timestamp, 0)
            XCTAssertEqual(meta.metaType, 0x51)
            let value = data.withUnsafeBytes { ptr -> UInt32 in
                var tmp: UInt32 = 0
                tmp |= UInt32(ptr[0]) << 16
                tmp |= UInt32(ptr[1]) << 8
                tmp |= UInt32(ptr[2])
                return tmp
            }
            XCTAssertEqual(value, 500_000)
        } else {
            XCTFail("Expected MetaEvent tempo")
        }
        if let meta = events[2] as? MetaEvent, let data = meta.rawData {
            XCTAssertEqual(meta.timestamp, 0)
            XCTAssertEqual(meta.metaType, 0x58)
            XCTAssertEqual(data[data.startIndex], 4)
            XCTAssertEqual(data[data.startIndex.advanced(by: 1)], 2)
            XCTAssertEqual(data[data.startIndex.advanced(by: 2)], 0x18)
            XCTAssertEqual(data[data.startIndex.advanced(by: 3)], 0x08)
        } else {
            XCTFail("Expected MetaEvent time signature")
        }
        if let noteOn = events[3] as? ChannelVoiceEvent {
            XCTAssertEqual(noteOn.timestamp, 0)
            XCTAssertEqual(noteOn.channel, 0)
            XCTAssertEqual(noteOn.noteNumber, 0x3C)
            XCTAssertEqual(noteOn.velocity, 0x40)
        } else {
            XCTFail("Expected ChannelVoiceEvent noteOn")
        }
        if let noteOff = events[4] as? ChannelVoiceEvent {
            XCTAssertEqual(noteOff.timestamp, 480)
            XCTAssertEqual(noteOff.channel, 0)
            XCTAssertEqual(noteOff.noteNumber, 0x3C)
            XCTAssertEqual(noteOff.velocity, 0x40)
        } else {
            XCTFail("Expected ChannelVoiceEvent noteOff")
        }
    }

    func testChannelPressureDecoding() throws {
        let bytes: [UInt8] = [
            0x4D, 0x54, 0x72, 0x6B,
            0x00, 0x00, 0x00, 0x07,
            0x00, 0xD0, 0x40,
            0x00, 0xFF, 0x2F, 0x00
        ]
        let events = try MidiFileParser.parseTrack(data: Data(bytes))
        XCTAssertEqual(events.count, 2)
        if let pressure = events[0] as? ChannelVoiceEvent {
            XCTAssertEqual(pressure.type, .channelPressure)
            XCTAssertEqual(pressure.channel, 0)
            XCTAssertEqual(pressure.controllerValue, 0x40)
        } else {
            XCTFail("Expected ChannelVoiceEvent channelPressure")
        }
    }

    func testPolyphonicKeyPressureDecoding() throws {
        let bytes: [UInt8] = [
            0x4D, 0x54, 0x72, 0x6B,
            0x00, 0x00, 0x00, 0x08,
            0x00, 0xA0, 0x3C, 0x40,
            0x00, 0xFF, 0x2F, 0x00
        ]
        let events = try MidiFileParser.parseTrack(data: Data(bytes))
        XCTAssertEqual(events.count, 2)
        if let pressure = events[0] as? ChannelVoiceEvent {
            XCTAssertEqual(pressure.type, .polyphonicKeyPressure)
            XCTAssertEqual(pressure.channel, 0)
            XCTAssertEqual(pressure.noteNumber, 0x3C)
            XCTAssertEqual(pressure.velocity, 0x40)
        } else {
            XCTFail("Expected ChannelVoiceEvent polyphonicKeyPressure")
        }
    }

    func testControlChangeDecoding() throws {
        let bytes: [UInt8] = [
            0x4D, 0x54, 0x72, 0x6B,
            0x00, 0x00, 0x00, 0x08,
            0x00, 0xB0, 0x07, 0x40,
            0x00, 0xFF, 0x2F, 0x00
        ]
        let events = try MidiFileParser.parseTrack(data: Data(bytes))
        XCTAssertEqual(events.count, 2)
        if let cc = events[0] as? ChannelVoiceEvent {
            XCTAssertEqual(cc.type, .controlChange)
            XCTAssertEqual(cc.channel, 0)
            XCTAssertEqual(cc.noteNumber, 0x07)
            XCTAssertEqual(cc.controllerValue, 0x40)
        } else {
            XCTFail("Expected ChannelVoiceEvent controlChange")
        }
    }

    func testProgramChangeDecoding() throws {
        let bytes: [UInt8] = [
            0x4D, 0x54, 0x72, 0x6B,
            0x00, 0x00, 0x00, 0x07,
            0x00, 0xC0, 0x05,
            0x00, 0xFF, 0x2F, 0x00
        ]
        let events = try MidiFileParser.parseTrack(data: Data(bytes))
        XCTAssertEqual(events.count, 2)
        if let program = events[0] as? ChannelVoiceEvent {
            XCTAssertEqual(program.type, .programChange)
            XCTAssertEqual(program.channel, 0)
            XCTAssertEqual(program.controllerValue, 0x05)
        } else {
            XCTFail("Expected ChannelVoiceEvent programChange")
        }
    }

    func testPitchBendDecoding() throws {
        let bytes: [UInt8] = [
            0x4D, 0x54, 0x72, 0x6B,
            0x00, 0x00, 0x00, 0x08,
            0x00, 0xE0, 0x00, 0x40,
            0x00, 0xFF, 0x2F, 0x00
        ]
        let events = try MidiFileParser.parseTrack(data: Data(bytes))
        XCTAssertEqual(events.count, 2)
        if let bend = events[0] as? ChannelVoiceEvent {
            XCTAssertEqual(bend.type, .pitchBend)
            XCTAssertEqual(bend.channel, 0)
            XCTAssertEqual(bend.controllerValue, 0x2000)
        } else {
            XCTFail("Expected ChannelVoiceEvent pitchBend")
        }
    }

    func testSystemMessageDecoding() throws {
        let bytes: [UInt8] = [
            0x4D, 0x54, 0x72, 0x6B,
            0x00, 0x00, 0x00, 0x0F,
            0x00, 0x90, 0x3C, 0x40,
            0x00, 0xF3, 0x05,
            0x00, 0x90, 0x3E, 0x40,
            0x00, 0xFF, 0x2F, 0x00
        ]
        let events = try MidiFileParser.parseTrack(data: Data(bytes))
        XCTAssertEqual(events.count, 4)
        if let system = events[1] as? UnknownEvent {
            XCTAssertEqual(system.rawData, Data([0xF3, 0x05]))
        } else {
            XCTFail("Expected UnknownEvent system message")
        }
    }

    func testSystemMessageClearsRunningStatus() throws {
        let bytes: [UInt8] = [
            0x4D, 0x54, 0x72, 0x6B,
            0x00, 0x00, 0x00, 0x0A,
            0x00, 0x90, 0x3C, 0x40,
            0x00, 0xF3, 0x05,
            0x00, 0x3E, 0x40
        ]
        let data = Data(bytes)
        XCTAssertThrowsError(try MidiFileParser.parseTrack(data: data)) { error in
            guard case MidiFileParserError.invalidEvent = error else {
                return XCTFail("Expected invalidEvent error")
            }
        }
    }

    func testRunningStatusDecoding() throws {
        let bytes: [UInt8] = [
            0x4D, 0x54, 0x72, 0x6B,
            0x00, 0x00, 0x00, 0x0B,
            0x00, 0x90, 0x3C, 0x40,
            0x00, 0x40, 0x40,
            0x00, 0xFF, 0x2F, 0x00
        ]
        let events = try MidiFileParser.parseTrack(data: Data(bytes))
        XCTAssertEqual(events.count, 3)
        if let first = events[0] as? ChannelVoiceEvent,
           let second = events[1] as? ChannelVoiceEvent {
            XCTAssertEqual(first.type, .noteOn)
            XCTAssertEqual(first.noteNumber, 0x3C)
            XCTAssertEqual(second.type, .noteOn)
            XCTAssertEqual(second.noteNumber, 0x40)
        } else {
            XCTFail("Expected ChannelVoiceEvent noteOn events")
        }
    }

    func testRealtimeMessagePreservesRunningStatus() throws {
        let bytes: [UInt8] = [
            0x4D, 0x54, 0x72, 0x6B,
            0x00, 0x00, 0x00, 0x0D,
            0x00, 0x90, 0x3C, 0x40,
            0x00, 0xF8,
            0x00, 0x3E, 0x40,
            0x00, 0xFF, 0x2F, 0x00
        ]
        let events = try MidiFileParser.parseTrack(data: Data(bytes))
        XCTAssertEqual(events.count, 4)
        if let first = events[0] as? ChannelVoiceEvent,
           let realtime = events[1] as? UnknownEvent,
           let second = events[2] as? ChannelVoiceEvent {
            XCTAssertEqual(first.type, .noteOn)
            XCTAssertEqual(realtime.rawData, Data([0xF8]))
            XCTAssertEqual(second.type, .noteOn)
            XCTAssertEqual(second.noteNumber, 0x3E)
        } else {
            XCTFail("Expected ChannelVoiceEvent, UnknownEvent, ChannelVoiceEvent")
        }
    }

    func testNoteOnZeroVelocityTreatedAsNoteOff() throws {
        let bytes: [UInt8] = [
            0x4D, 0x54, 0x72, 0x6B,
            0x00, 0x00, 0x00, 0x08,
            0x00, 0x90, 0x3C, 0x00,
            0x00, 0xFF, 0x2F, 0x00
        ]
        let events = try MidiFileParser.parseTrack(data: Data(bytes))
        XCTAssertEqual(events.count, 2)
        if let note = events[0] as? ChannelVoiceEvent {
            XCTAssertEqual(note.type, .noteOff)
            XCTAssertEqual(note.velocity, 0)
            XCTAssertEqual(note.noteNumber, 0x3C)
        } else {
            XCTFail("Expected ChannelVoiceEvent noteOff")
        }
    }

    func testTimestampAccumulation() throws {
        let bytes: [UInt8] = [
            0x4D, 0x54, 0x72, 0x6B,
            0x00, 0x00, 0x00, 0x10,
            0x00, 0x90, 0x3C, 0x40,
            0x18, 0x80, 0x3C, 0x40,
            0x0C, 0x90, 0x3E, 0x40,
            0x00, 0xFF, 0x2F, 0x00
        ]
        let events = try MidiFileParser.parseTrack(data: Data(bytes))
        XCTAssertEqual(events.count, 4)
        if let first = events[0] as? ChannelVoiceEvent,
           let second = events[1] as? ChannelVoiceEvent,
           let third = events[2] as? ChannelVoiceEvent {
            XCTAssertEqual(first.timestamp, 0)
            XCTAssertEqual(second.timestamp, 24)
            XCTAssertEqual(third.timestamp, 36)
        } else {
            XCTFail("Expected ChannelVoiceEvent note events")
        }
    }

    func testSysExEventDecoding() throws {
        let bytes: [UInt8] = [
            0x4D, 0x54, 0x72, 0x6B,
            0x00, 0x00, 0x00, 0x0A,
            0x00, 0xF0, 0x03, 0x01, 0x02, 0x03,
            0x00, 0xFF, 0x2F, 0x00
        ]
        let events = try MidiFileParser.parseTrack(data: Data(bytes))
        XCTAssertEqual(events.count, 2)
        if let sysEx = events[0] as? SysExEvent {
            XCTAssertEqual(sysEx.rawData, Data([0x01, 0x02, 0x03]))
        } else {
            XCTFail("Expected SysExEvent")
        }
    }

    func testUnknownMetaEventPreserved() throws {
        let bytes: [UInt8] = [
            0x4D, 0x54, 0x72, 0x6B,
            0x00, 0x00, 0x00, 0x09,
            0x00, 0xFF, 0x7F, 0x01, 0x42,
            0x00, 0xFF, 0x2F, 0x00
        ]
        let events = try MidiFileParser.parseTrack(data: Data(bytes))
        XCTAssertEqual(events.count, 2)
        if let meta = events[0] as? MetaEvent {
            XCTAssertEqual(meta.metaType, 0x7F)
            XCTAssertEqual(meta.rawData, Data([0x42]))
        } else {
            XCTFail("Expected MetaEvent with type 0x7F")
        }
    }

    func testInvalidHeaderThrows() {
        let bytes: [UInt8] = [
            0x4D, 0x54, 0x68, 0x64,
            0x00, 0x00, 0x00, 0x06,
            0x00
        ]
        let data = Data(bytes)
        XCTAssertThrowsError(try MidiFileParser.parseHeader(data: data)) { error in
            guard case MidiFileParserError.invalidHeader = error else {
                return XCTFail("Expected invalidHeader error")
            }
        }
    }

    func testInvalidTrackChunkThrows() {
        let bytes: [UInt8] = [
            0x4D, 0x54, 0x68, 0x64,
            0x00, 0x00, 0x00, 0x00
        ]
        let data = Data(bytes)
        XCTAssertThrowsError(try MidiFileParser.parseTrack(data: data)) { error in
            guard case MidiFileParserError.invalidTrack = error else {
                return XCTFail("Expected invalidTrack error")
            }
        }
    }

    func testTruncatedTrackLengthThrows() {
        let bytes: [UInt8] = [
            0x4D, 0x54, 0x72, 0x6B,
            0x00, 0x00, 0x00, 0x08,
            0x00
        ]
        let data = Data(bytes)
        XCTAssertThrowsError(try MidiFileParser.parseTrack(data: data)) { error in
            guard case MidiFileParserError.invalidTrack = error else {
                return XCTFail("Expected invalidTrack error")
            }
        }
    }

    func testInvalidEventThrows() {
        let bytes: [UInt8] = [
            0x4D, 0x54, 0x72, 0x6B,
            0x00, 0x00, 0x00, 0x02,
            0x00, 0x90
        ]
        let data = Data(bytes)
        XCTAssertThrowsError(try MidiFileParser.parseTrack(data: data)) { error in
            guard case MidiFileParserError.invalidEvent = error else {
                return XCTFail("Expected invalidEvent error")
            }
        }
    }
}
// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
