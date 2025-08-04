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
}
// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
