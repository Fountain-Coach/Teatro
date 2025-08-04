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

    func testSystemMessageDecoding() throws {
        let bytes: [UInt8] = [0x12, 0xF8, 0x00, 0x00]
        let events = try UMPParser.parse(data: Data(bytes))
        guard let event = events.first as? UnknownEvent else {
            return XCTFail("Expected UnknownEvent")
        }
        XCTAssertEqual(event.rawData, Data(bytes))
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
        XCTAssertEqual(event.velocity, 0x7F)
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

    func testGroupChannelMapping() throws {
        // Group 2, channel 10 should map to unified channel 42
        let bytes: [UInt8] = [0x22, 0x9A, 0x3C, 0x40]
        let events = try UMPParser.parse(data: Data(bytes))
        guard let event = events.first as? ChannelVoiceEvent else {
            return XCTFail("Expected ChannelVoiceEvent")
        }
        XCTAssertEqual(event.channel, 0x2A)
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
