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
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.

