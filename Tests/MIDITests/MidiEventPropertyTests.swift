import XCTest
@testable import Teatro

final class MidiEventPropertyTests: XCTestCase {
    func testDefaultGroupIsNil() {
        let event = MetaEvent(timestamp: 0, meta: 0x01, data: Data())
        XCTAssertNil(event.group)
    }

    func testChannelVoiceEventMetaAndRawDataNil() {
        let event = ChannelVoiceEvent(timestamp: 0, type: .noteOn, group: nil, channel: 1, noteNumber: 60, velocity: 100, controllerValue: nil)
        XCTAssertNil(event.metaType)
        XCTAssertNil(event.rawData)
    }

    func testMetaEventPropertiesNil() {
        let event = MetaEvent(timestamp: 0, meta: 0x01, data: Data())
        XCTAssertNil(event.noteNumber)
        XCTAssertNil(event.velocity)
        XCTAssertNil(event.controllerValue)
    }

    func testTempoEventProperties() {
        let event = TempoEvent(timestamp: 0, microsecondsPerQuarter: 500000)
        XCTAssertEqual(event.type, .meta)
        XCTAssertNil(event.channel)
        XCTAssertNil(event.noteNumber)
        XCTAssertNil(event.velocity)
        XCTAssertNil(event.controllerValue)
        XCTAssertEqual(event.metaType, 0x51)
        XCTAssertEqual(event.rawData, Data([0x07, 0xA1, 0x20]))
    }

    func testTimeSignatureEventProperties() {
        let event = TimeSignatureEvent(timestamp: 0, numerator: 4, denominator: 4, metronome: 24, thirtySeconds: 8)
        XCTAssertEqual(event.type, .meta)
        XCTAssertNil(event.channel)
        XCTAssertNil(event.noteNumber)
        XCTAssertNil(event.velocity)
        XCTAssertNil(event.controllerValue)
        XCTAssertEqual(event.metaType, 0x58)
        XCTAssertEqual(event.rawData, Data([4, 2, 24, 8]))
    }

    func testTrackNameEventProperties() {
        let event = TrackNameEvent(timestamp: 0, name: "Track")
        XCTAssertEqual(event.type, .meta)
        XCTAssertNil(event.channel)
        XCTAssertNil(event.noteNumber)
        XCTAssertNil(event.velocity)
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
