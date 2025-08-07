import XCTest
@testable import Teatro

final class MIDI2Tests: XCTestCase {
    func testUMPEncoderProducesWords() {
        let note = MIDI2Note(channel: 0, note: 60, velocity: MIDI.fromUnitFloat(0.5), duration: 0.1)
        let packets = UMPEncoder.encode(note)
        XCTAssertEqual(packets, [0x40903C00, MIDI.fromUnitFloat(0.5)])
    }

    func testCSDRendererWritesFile() throws {
        let score = CsoundScore(orchestra: "f 1 0 0 10 1", score: "i1 0 1 0.5")
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("csd")
        CSDRenderer.renderToFile(score, to: url.path)
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
    }

    func test32BitVelocityParsingFromFixture() throws {
        let fixtures = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Fixtures")
        let jsonData = try Data(contentsOf: fixtures.appendingPathComponent("ump_packets.json"))
        let object = try JSONSerialization.jsonObject(with: jsonData) as? [String: [NSNumber]]
        guard let bytes = object?["noteOn32Velocity"]?.map({ UInt8(truncating: $0) }) else {
            return XCTFail("Missing fixture")
        }
        let events = try UMPParser.parse(data: Data(bytes))
        guard let event = events.first as? ChannelVoiceEvent else {
            return XCTFail("Expected ChannelVoiceEvent")
        }
        XCTAssertEqual(event.velocity, 0x12345678)
    }

    func testPerNoteControllerParsingFromFixture() throws {
        let fixtures = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Fixtures")
        let jsonData = try Data(contentsOf: fixtures.appendingPathComponent("ump_packets.json"))
        let object = try JSONSerialization.jsonObject(with: jsonData) as? [String: [NSNumber]]
        guard let bytes = object?["perNoteController"]?.map({ UInt8(truncating: $0) }) else {
            return XCTFail("Missing fixture")
        }
        let events = try UMPParser.parse(data: Data(bytes))
        guard let event = events.first as? PerNoteControllerEvent else {
            return XCTFail("Expected PerNoteControllerEvent")
        }
        XCTAssertEqual(event.controllerIndex, 0x01)
        XCTAssertEqual(event.controllerValue, 0x01020304)
    }

    func testJRTimestampParsingFromFixture() throws {
        let fixtures = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Fixtures")
        let jsonData = try Data(contentsOf: fixtures.appendingPathComponent("ump_packets.json"))
        let object = try JSONSerialization.jsonObject(with: jsonData) as? [String: [NSNumber]]
        guard let bytes = object?["jrTimestamp"]?.map({ UInt8(truncating: $0) }) else {
            return XCTFail("Missing fixture")
        }
        let events = try UMPParser.parse(data: Data(bytes))
        guard let event = events.first as? JRTimestampEvent else {
            return XCTFail("Expected JRTimestampEvent")
        }
        XCTAssertEqual(event.value, 0x00000001)
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
