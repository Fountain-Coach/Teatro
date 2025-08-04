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
            0x00, 0x00, 0x00, 0x15, // length 21
            // 0 delta, meta track name "Test"
            0x00, 0xFF, 0x03, 0x04, 0x54, 0x65, 0x73, 0x74,
            // 0 delta, note on C4 velocity 64
            0x00, 0x90, 0x3C, 0x40,
            // 480 delta, note off
            0x83, 0x60, 0x80, 0x3C, 0x40,
            // 0 delta, end of track
            0x00, 0xFF, 0x2F, 0x00
        ]
        let data = Data(bytes)
        let events = try MidiFileParser.parseTrack(data: data)
        XCTAssertEqual(events.count, 4)
        if case let .noteOn(delta, channel, note, velocity) = events[1] {
            XCTAssertEqual(delta, 0)
            XCTAssertEqual(channel, 0)
            XCTAssertEqual(note, 0x3C)
            XCTAssertEqual(velocity, 0x40)
        } else {
            XCTFail("Expected noteOn event")
        }
        if case let .noteOff(delta, channel, note, velocity) = events[2] {
            XCTAssertEqual(delta, 480)
            XCTAssertEqual(channel, 0)
            XCTAssertEqual(note, 0x3C)
            XCTAssertEqual(velocity, 0x40)
        } else {
            XCTFail("Expected noteOff event")
        }
    }
}

© 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
