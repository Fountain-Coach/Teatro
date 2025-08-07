import XCTest
import Foundation
@testable import Teatro

final class UMPEncoderCoverageTests: XCTestCase {
    func testEncodeEventVariants() {
        let cases: [(MidiEventProtocol, UInt32)] = [
            (ChannelVoiceEvent(timestamp: 0, type: .noteOn, group: nil, channel: 0, noteNumber: 60, velocity: 64, controllerValue: nil), 0x20903C40),
            (ChannelVoiceEvent(timestamp: 0, type: .noteOff, group: 1, channel: 2, noteNumber: 60, velocity: 0, controllerValue: nil), 0x21823C00),
            (ChannelVoiceEvent(timestamp: 0, type: .polyphonicKeyPressure, group: nil, channel: 3, noteNumber: 61, velocity: 70, controllerValue: nil), 0x20A33D46),
            (ChannelVoiceEvent(timestamp: 0, type: .controlChange, group: nil, channel: 4, noteNumber: 7, velocity: nil, controllerValue: 2), 0x20B40702),
            (ChannelVoiceEvent(timestamp: 0, type: .programChange, group: nil, channel: 5, noteNumber: nil, velocity: nil, controllerValue: 1), 0x20C50100),
            (ChannelVoiceEvent(timestamp: 0, type: .channelPressure, group: nil, channel: 6, noteNumber: nil, velocity: nil, controllerValue: 3), 0x20D60300),
            (ChannelVoiceEvent(timestamp: 0, type: .pitchBend, group: nil, channel: 7, noteNumber: nil, velocity: nil, controllerValue: 0x2000), 0x20E70040)
        ]
        for (event, expected) in cases {
            XCTAssertEqual(UMPEncoder.encodeEvent(event).first, expected)
        }
    }

    func testEncodeEventDefaultGroupAndUnknown() {
        let event = ChannelVoiceEvent(timestamp: 0, type: .noteOn, group: nil, channel: 0, noteNumber: 60, velocity: 64, controllerValue: nil)
        let words = UMPEncoder.encodeEvent(event, defaultGroup: 2)
        XCTAssertEqual(words, [0x22903C40])

        let meta = MetaEvent(timestamp: 0, meta: 0x2F, data: Data())
        XCTAssertTrue(UMPEncoder.encodeEvent(meta).isEmpty)

        let noChannel = ChannelVoiceEvent(timestamp: 0, type: .noteOn, group: nil, channel: nil, noteNumber: 60, velocity: 64, controllerValue: nil)
        XCTAssertTrue(UMPEncoder.encodeEvent(noChannel).isEmpty)
    }

    func testLongSysExEncoding() {
        let sysEx7 = Data([0xF0, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0xF7])
        let event7 = SysExEvent(timestamp: 0, data: sysEx7, group: 0)
        let words7 = UMPEncoder.encodeEvent(event7)
        XCTAssertEqual(words7, [0x5016F001, 0x02030405, 0x50360607, 0x08090AF7])

        let sysEx8 = Data([0xF0, 0x80, 0x81, 0x82, 0x83, 0x84, 0x85, 0x86, 0x87, 0x88, 0x89, 0x8A, 0x8B, 0x8C, 0xF7])
        let event8 = SysExEvent(timestamp: 0, data: sysEx8, group: 0)
        let words8 = UMPEncoder.encodeEvent(event8)
        XCTAssertEqual(words8, [0x601AF080, 0x81828384, 0x85868788, 0x6035898A, 0x8B8CF700, 0x00000000])
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.

