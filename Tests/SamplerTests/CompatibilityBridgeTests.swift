import XCTest
@testable import Teatro

final class CompatibilityBridgeTests: XCTestCase {
    func testCompatibilityBridgeDowncasts() {
        let event = MIDI2Note(channel: 0, note: 64, velocity: 1.0, duration: 1.0)
        let midi1 = MIDICompatibilityBridge.toMIDINote(MIDI2NoteEvent(channel: event.channel, note: event.note, velocity: event.velocity, pitch: Float(event.note), timbre: .zero, articulation: "legato", timestamp: 0))
        XCTAssertEqual(midi1.note, 64)
        XCTAssertEqual(midi1.velocity, 127)
    }

    func testCompatibilityBridgeCsound() {
        let event = MIDI2NoteEvent(channel: 0, note: 60, velocity: 0.5, pitch: 60, timbre: .zero, articulation: "none", timestamp: 0)
        let cs = MIDICompatibilityBridge.toCsoundScore(event)
        let rendered = cs.render()
        XCTAssertTrue(rendered.contains("i1"))
    }

    func testCompatibilityBridgeLily() {
        let event = MIDI2NoteEvent(channel: 0, note: 60, velocity: 0.8, pitch: 60, timbre: .zero, articulation: "none", timestamp: 0)
        let lily = MIDICompatibilityBridge.toLilyScore(event)
        let content = lily.render()
        XCTAssertTrue(content.contains("c'4"))
    }

    func testLilyScoreDynamics() {
        let cases: [(Float, String)] = [
            (0.95, "\\ff"),
            (0.75, "\\f"),
            (0.55, "\\mf"),
            (0.35, "\\p"),
            (0.1, "\\pp")
        ]
        for (vel, dyn) in cases {
            let event = MIDI2NoteEvent(channel: 0, note: 60, velocity: vel, pitch: 60, timbre: .zero, articulation: "none", timestamp: 0)
            let content = MIDICompatibilityBridge.toLilyScore(event).render()
            XCTAssertTrue(content.contains(dyn))
        }
    }

    func testLilyScoreLowerOctave() {
        let event = MIDI2NoteEvent(channel: 0, note: 24, velocity: 0.5, pitch: 24, timbre: .zero, articulation: "none", timestamp: 0)
        let content = MIDICompatibilityBridge.toLilyScore(event).render()
        XCTAssertTrue(content.contains("c,,4"))
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
