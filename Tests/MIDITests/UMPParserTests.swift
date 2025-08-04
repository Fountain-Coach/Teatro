import XCTest
@testable import Teatro

final class UMPParserTests: XCTestCase {
    func testUtilityMessageDecoding() throws {
        let bytes: [UInt8] = [0x02, 0x7F, 0xAA, 0xBB]
        let events = try UMPParser.parse(data: Data(bytes))
        guard case let .utilityMessage(group, status, data1, data2) = events.first else {
            return XCTFail("Expected utilityMessage event")
        }
        XCTAssertEqual(group, 2)
        XCTAssertEqual(status, 0x7F)
        XCTAssertEqual(data1, 0xAA)
        XCTAssertEqual(data2, 0xBB)
    }

    func testMIDI1ChannelVoiceDecoding() throws {
        let bytes: [UInt8] = [0x20, 0x90, 0x3C, 0x40]
        let events = try UMPParser.parse(data: Data(bytes))
        guard case let .midi1ChannelVoice(group, channel, status, data1, data2) = events.first else {
            return XCTFail("Expected midi1ChannelVoice event")
        }
        XCTAssertEqual(group, 0)
        XCTAssertEqual(channel, 0)
        XCTAssertEqual(status, 0x90)
        XCTAssertEqual(data1, 0x3C)
        XCTAssertEqual(data2, 0x40)
    }

    func testSystemMessageDecoding() throws {
        let bytes: [UInt8] = [0x12, 0xF8, 0x00, 0x00]
        let events = try UMPParser.parse(data: Data(bytes))
        guard case let .systemMessage(group, status, data1, data2) = events.first else {
            return XCTFail("Expected systemMessage event")
        }
        XCTAssertEqual(group, 2)
        XCTAssertEqual(status, 0xF8)
        XCTAssertEqual(data1, 0)
        XCTAssertEqual(data2, 0)
    }

    func testMIDI2ChannelVoiceDecoding() throws {
        let bytes: [UInt8] = [
            0x40, 0x90, 0x3C, 0x00,
            0x7F, 0x00, 0x00, 0x00
        ]
        let events = try UMPParser.parse(data: Data(bytes))
        guard case let .midi2ChannelVoice(group, channel, status, data1, data2) = events.first else {
            return XCTFail("Expected midi2ChannelVoice event")
        }
        XCTAssertEqual(group, 0)
        XCTAssertEqual(channel, 0)
        XCTAssertEqual(status, 0x90)
        XCTAssertEqual(data1, 0x3C00)
        XCTAssertEqual(data2, 0x7F000000)
    }

    func testUnknownPacketPreserved() throws {
        let bytes: [UInt8] = [
            0x50, 0x00, 0x00, 0x00,
            0x01, 0x02, 0x03, 0x04
        ]
        let events = try UMPParser.parse(data: Data(bytes))
        guard case let .unknown(group, rawWords) = events.first else {
            return XCTFail("Expected unknown event")
        }
        XCTAssertEqual(group, 0)
        XCTAssertEqual(rawWords.count, 2)
        XCTAssertEqual(rawWords[0], 0x50000000)
        XCTAssertEqual(rawWords[1], 0x01020304)
    }

    func testMisalignedDataThrows() {
        let bytes: [UInt8] = [0x00]
        XCTAssertThrowsError(try UMPParser.parse(data: Data(bytes))) { error in
            guard case UMPParserError.misaligned = error else {
                return XCTFail("Expected misaligned error")
            }
        }
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
