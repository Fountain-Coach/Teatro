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

