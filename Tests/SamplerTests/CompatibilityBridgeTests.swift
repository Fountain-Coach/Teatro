import XCTest
import MIDI2
@testable import Teatro

final class CompatibilityBridgeTests: XCTestCase {
    func testCompatibilityBridgeDowncasts() {
        let vel = UInt16((MIDI.fromUnitFloat(1.0) >> 16) & 0xFFFF)
        let note = Midi2NoteOn(group: Uint4(0)!, channel: Uint4(0)!, note: Uint7(64)!, velocity: vel)
        let midi1 = MIDICompatibilityBridge.toMIDINote(note)
        XCTAssertEqual(midi1.note, 64)
        XCTAssertEqual(midi1.velocity, 127)
    }

    func testCompatibilityBridgeCsound() {
        let vel = UInt16(Double(UInt16.max) * 0.5)
        let note = Midi2NoteOn(group: Uint4(0)!, channel: Uint4(0)!, note: Uint7(60)!, velocity: vel)
        let cs = MIDICompatibilityBridge.toCsoundScore(note)
        let rendered = cs.render()
        XCTAssertTrue(rendered.contains("i1"))
    }

    func testCompatibilityBridgeLily() {
        let vel = UInt16(Double(UInt16.max) * 0.8)
        let note = Midi2NoteOn(group: Uint4(0)!, channel: Uint4(0)!, note: Uint7(60)!, velocity: vel)
        let lily = MIDICompatibilityBridge.toLilyScore(note)
        let content = lily.render()
        XCTAssertTrue(content.contains("c'4"))
    }

    func testLilyScoreDynamics() {
        let cases: [(Double, String)] = [
            (0.95, "\\ff"),
            (0.75, "\\f"),
            (0.55, "\\mf"),
            (0.35, "\\p"),
            (0.1, "\\pp")
        ]
        for (vel, dyn) in cases {
            let v = UInt16((Double(UInt16.max) * vel).rounded())
            let note = Midi2NoteOn(group: Uint4(0)!, channel: Uint4(0)!, note: Uint7(60)!, velocity: v)
            let content = MIDICompatibilityBridge.toLilyScore(note).render()
            XCTAssertTrue(content.contains(dyn))
        }
    }

    func testLilyScoreLowerOctave() {
        let vel = UInt16(Double(UInt16.max) * 0.5)
        let note = Midi2NoteOn(group: Uint4(0)!, channel: Uint4(0)!, note: Uint7(24)!, velocity: vel)
        let content = MIDICompatibilityBridge.toLilyScore(note).render()
        XCTAssertTrue(content.contains("c,,4"))
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
