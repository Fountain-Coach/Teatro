import Foundation
import XCTest
@testable import Teatro

final class UMPParserTests: XCTestCase {
    func testChannelVoiceEventGroupAndChannel() throws {
        let bytes: [UInt8] = [0x22, 0x93, 0x3C, 0x40]
        let events = try UMPParser.parse(data: Data(bytes))
        XCTAssertEqual(events.count, 1)
        if let event = events.first as? ChannelVoiceEvent {
            XCTAssertEqual(event.group, 0x2)
            XCTAssertEqual(event.channel, 0x3)
            XCTAssertEqual(event.noteNumber, 0x3C)
            XCTAssertEqual(event.velocity, 0x40)
        } else {
            XCTFail("Expected ChannelVoiceEvent")
        }
    }

    func testSysEx7EventDecoding() throws {
        let bytes: [UInt8] = [
            0x50, 0x00, 0x12, 0x34,
            0x56, 0x78, 0x9A, 0xBC
        ]
        let events = try UMPParser.parse(data: Data(bytes))
        XCTAssertEqual(events.count, 1)
        XCTAssertTrue(events.first is SysExEvent)
    }

    func test32BitVelocityDecoding() throws {
        let bytes: [UInt8] = [
            0x40, 0x90, 0x3C, 0x00,
            0x12, 0x34, 0x56, 0x78
        ]
        let events = try UMPParser.parse(data: Data(bytes))
        XCTAssertEqual(events.count, 1)
        guard let event = events.first as? NoteOnWithAttributeEvent else {
            return XCTFail("Expected NoteOnWithAttributeEvent")
        }
        XCTAssertEqual(event.velocity, 0x12340000)
        XCTAssertEqual(event.attributeType.rawValue, 0x00)
        XCTAssertEqual(event.attributeData, 0x5678)
    }

    func testPerNoteControllerDecoding() throws {
        let bytes: [UInt8] = [
            0x40, 0x00, 0x3C, 0x01,
            0x00, 0x00, 0x00, 0x05
        ]
        let events = try UMPParser.parse(data: Data(bytes))
        XCTAssertEqual(events.count, 1)
        guard let event = events.first as? PerNoteControllerEvent else {
            return XCTFail("Expected PerNoteControllerEvent")
        }
        XCTAssertEqual(event.noteNumber, 0x3C)
        XCTAssertEqual(event.controllerIndex, 0x01)
        XCTAssertEqual(event.controllerValue, 0x00000005)
    }

    func testJRTimestampParsing() throws {
        let bytes: [UInt8] = [
            0x10, 0x00, 0x00, 0x01,
            0x40, 0x90, 0x3C, 0x00,
            0x00, 0x00, 0x00, 0x01
        ]
        let events = try UMPParser.parse(data: Data(bytes))
        XCTAssertEqual(events.count, 2)
        XCTAssertTrue(events.first is JRTimestampEvent)
        XCTAssertTrue(events.last is NoteOnWithAttributeEvent)
    }

    func testTruncatedPacketThrows() {
        let bytes: [UInt8] = [0x40, 0x90, 0x3C, 0x00]
        XCTAssertThrowsError(try UMPParser.parse(data: Data(bytes))) { error in
            guard case UMPParserError.truncated = error else {
                return XCTFail("Expected truncated error")
            }
        }
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.

