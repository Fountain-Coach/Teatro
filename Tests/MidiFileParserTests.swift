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
}

© 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
