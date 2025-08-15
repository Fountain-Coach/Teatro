import XCTest
import MIDI2
@testable import Teatro

// Refs: teatro-root

final class MIDI1BridgeTests: XCTestCase {
    func testNoteOnRoundTripPreservesGroupChannel() throws {
        let note = Midi2NoteOn(group: Uint4(2)!, channel: Uint4(3)!, note: Uint7(60)!, velocity: 0x7F00)
        let packet = note.ump()
        var data = Data()
        for w in packet.words { var be = w.bigEndian; withUnsafeBytes(of: &be) { data.append(contentsOf: $0) } }
        let midi1 = try MIDI1Bridge.umpToMIDI1(data)
        let round = MIDI1Bridge.midi1ToUMP(midi1, group: 2)
        XCTAssertEqual(round.count, 1)
        let word = round[0]
        XCTAssertEqual(UInt8((word >> 24) & 0xF), 2)
        XCTAssertEqual(UInt8((word >> 20) & 0xF), 0x9)
        XCTAssertEqual(UInt8((word >> 16) & 0xF), 3)
        XCTAssertEqual(UInt8((word >> 8) & 0x7F), 60)
        let expected = MIDI.midi1Velocity(from: UInt32(note.velocity) << 16)
        XCTAssertEqual(UInt8(word & 0x7F), expected)
    }

    func testNoteOffRoundTripPreservesGroupChannel() throws {
        let off = NoteOff(group: Uint4(2)!, channel: Uint4(3)!, noteNumber: Uint7(60)!, velocity: 0x4000)
        let packet = off.ump()
        var data = Data()
        for w in [packet.word0, packet.word1] { var be = w.bigEndian; withUnsafeBytes(of: &be) { data.append(contentsOf: $0) } }
        let midi1 = try MIDI1Bridge.umpToMIDI1(data)
        let round = MIDI1Bridge.midi1ToUMP(midi1, group: 2)
        XCTAssertEqual(round.count, 1)
        let word = round[0]
        XCTAssertEqual(UInt8((word >> 24) & 0xF), 2)
        XCTAssertEqual(UInt8((word >> 20) & 0xF), 0x8)
        XCTAssertEqual(UInt8((word >> 16) & 0xF), 3)
        XCTAssertEqual(UInt8((word >> 8) & 0x7F), 60)
        let expected = MIDI.midi1Velocity(from: UInt32(off.velocity) << 16)
        XCTAssertEqual(UInt8(word & 0x7F), expected)
    }

    func testControlChangeRoundTripPreservesGroupChannel() throws {
        let cc = ControlChange(group: Uint4(1)!, channel: Uint4(5)!, control: Uint7(7)!, value: 0x12345678)
        let packet = cc.ump()
        var data = Data()
        for w in packet.words { var be = w.bigEndian; withUnsafeBytes(of: &be) { data.append(contentsOf: $0) } }
        let midi1 = try MIDI1Bridge.umpToMIDI1(data)
        let round = MIDI1Bridge.midi1ToUMP(midi1, group: 1)
        XCTAssertEqual(round.count, 1)
        let word = round[0]
        XCTAssertEqual(UInt8((word >> 24) & 0xF), 1)
        XCTAssertEqual(UInt8((word >> 20) & 0xF), 0xB)
        XCTAssertEqual(UInt8((word >> 16) & 0xF), 5)
        XCTAssertEqual(UInt8((word >> 8) & 0x7F), 7)
        let expected = MIDI.midi1Controller(from: cc.value)
        XCTAssertEqual(UInt8(word & 0x7F), expected)
    }

    func testPitchBendRoundTripPreservesGroupChannel() throws {
        let pb = PitchBend(group: Uint4(0)!, channel: Uint4(4)!, value: 0x11223344)
        let packet = pb.ump()
        var data = Data()
        for w in packet.words { var be = w.bigEndian; withUnsafeBytes(of: &be) { data.append(contentsOf: $0) } }
        let midi1 = try MIDI1Bridge.umpToMIDI1(data)
        let round = MIDI1Bridge.midi1ToUMP(midi1, group: 0)
        XCTAssertEqual(round.count, 1)
        let word = round[0]
        XCTAssertEqual(UInt8((word >> 24) & 0xF), 0)
        XCTAssertEqual(UInt8((word >> 20) & 0xF), 0xE)
        XCTAssertEqual(UInt8((word >> 16) & 0xF), 4)
        let lsb = UInt8((word >> 8) & 0x7F)
        let msb = UInt8(word & 0x7F)
        let combined = UInt16(msb) << 7 | UInt16(lsb)
        XCTAssertEqual(combined, MIDI.midi1PitchBend(from: pb.value))
    }

    func testUnsupportedMessagesGraceful() throws {
        let umpBytes: [UInt8] = [0x00, 0x00, 0x00, 0x00]
        let midi1 = try MIDI1Bridge.umpToMIDI1(Data(umpBytes))
        XCTAssertTrue(midi1.isEmpty)
        let words = MIDI1Bridge.midi1ToUMP(Data([0xF2, 0x01, 0x02]))
        XCTAssertTrue(words.isEmpty)
    }

    func testRunningStatusConversion() {
        let midi1 = Data([0x90, 0x40, 0x7F, 0x41, 0x7F])
        let words = MIDI1Bridge.midi1ToUMP(midi1)
        XCTAssertEqual(words.count, 2)
        for w in words {
            XCTAssertEqual(UInt8((w >> 20) & 0xF), 0x9)
        }
    }

    func testPitchBendEdgeConversion() throws {
        let midi1 = Data([0xE0, 0x00, 0x00, 0xE0, 0x7F, 0x7F])
        let words = MIDI1Bridge.midi1ToUMP(midi1)
        var data = Data()
        for word in words { var be = word.bigEndian; withUnsafeBytes(of: &be) { data.append(contentsOf: $0) } }
        let roundTrip = try MIDI1Bridge.umpToMIDI1(data)
        XCTAssertEqual(roundTrip.count % 3, 0)
    }

    func testBridgeToAudioSink() throws {
        final class MockSink: MIDIAudioSink {
            var calls: [(String, UInt8, UInt8, UInt8)] = []
            func noteOn(note: UInt8, vel: UInt8, ch: UInt8) { calls.append(("on", note, vel, ch)) }
            func noteOff(note: UInt8, ch: UInt8) { calls.append(("off", note, 0, ch)) }
            func controlChange(cc: UInt8, value: UInt8, ch: UInt8) { calls.append(("cc", cc, value, ch)) }
        }
        let note = Midi2NoteOn(group: Uint4(0)!, channel: Uint4(1)!, note: Uint7(60)!, velocity: 0x7F00)
        let packet = note.ump()
        var data = Data()
        for w in packet.words { var be = w.bigEndian; withUnsafeBytes(of: &be) { data.append(contentsOf: $0) } }
        let sink = MockSink()
        try MIDI1Bridge.umpToMIDI1(data, sink: sink)
        XCTAssertEqual(sink.calls.count, 1)
        if let first = sink.calls.first {
            XCTAssertEqual(first.0, "on")
            XCTAssertEqual(first.1, 60)
            XCTAssertEqual(first.2, 127)
            XCTAssertEqual(first.3, 1)
        }
    }
}
