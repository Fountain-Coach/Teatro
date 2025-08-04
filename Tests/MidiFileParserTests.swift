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
        if case let .trackName(delta, name) = events[0] {
            XCTAssertEqual(delta, 0)
            XCTAssertEqual(name, "Test")
        } else {
            XCTFail("Expected trackName event")
        }
        if case let .tempo(delta, microseconds) = events[1] {
            XCTAssertEqual(delta, 0)
            XCTAssertEqual(microseconds, 500_000)
        } else {
            XCTFail("Expected tempo event")
        }
        if case let .timeSignature(delta, num, denom, metro, thirty) = events[2] {
            XCTAssertEqual(delta, 0)
            XCTAssertEqual(num, 4)
            XCTAssertEqual(denom, 2)
            XCTAssertEqual(metro, 0x18)
            XCTAssertEqual(thirty, 0x08)
        } else {
            XCTFail("Expected timeSignature event")
        }
        if case let .noteOn(delta, channel, note, velocity) = events[3] {
            XCTAssertEqual(delta, 0)
            XCTAssertEqual(channel, 0)
            XCTAssertEqual(note, 0x3C)
            XCTAssertEqual(velocity, 0x40)
        } else {
            XCTFail("Expected noteOn event")
        }
        if case let .noteOff(delta, channel, note, velocity) = events[4] {
            XCTAssertEqual(delta, 480)
            XCTAssertEqual(channel, 0)
            XCTAssertEqual(note, 0x3C)
            XCTAssertEqual(velocity, 0x40)
        } else {
            XCTFail("Expected noteOff event")
        }
    }
}
// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
