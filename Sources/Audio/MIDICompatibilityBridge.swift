import Foundation

/// Provides downcasting of MIDI 2.0 note events to legacy formats for
/// Csound and LilyPond while maintaining MIDI 2.0 expressiveness.
public struct MIDICompatibilityBridge {
    public static func toMIDINote(_ event: Midi2NoteOn) -> MIDINote {
        MIDINote(
            channel: Int(event.channel.rawValue),
            note: Int(event.note.rawValue),
            velocity: Int(MIDI.midi1Velocity(from: UInt32(event.velocity) << 16)),
            duration: 0.1
        )
    }

    public static func toCsoundScore(_ event: Midi2NoteOn) -> CsoundScore {
        let pitch = Double(event.note.rawValue)
        let frequency = 440.0 * pow(2.0, (pitch - 69.0) / 12.0)
        let amplitude = Double(event.velocity) / Double(UInt16.max)
        let scoreLine = String(
            format: "i1 0.000 0.100 %.3f %.3f",
            amplitude,
            frequency
        )

        let orchestra = """
        f 1 0 0 10 1
        instr 1
            a1 oscili p4, p5, 1
            outs a1, a1
        endin
        """

        return CsoundScore(orchestra: orchestra, score: scoreLine)
    }

    public static func toLilyScore(_ event: Midi2NoteOn) -> LilyScore {
        let names = ["c", "cis", "d", "dis", "e", "f", "fis", "g", "gis", "a", "ais", "b"]
        let value = Int(event.note.rawValue)
        let name = names[value % 12]
        let octave = value / 12
        var note = name
        let baseOctave = 4
        if octave > baseOctave {
            note += String(repeating: "'", count: octave - baseOctave)
        } else if octave < baseOctave {
            note += String(repeating: ",", count: baseOctave - octave)
        }
        note += "4"

        let vel = Double(event.velocity) / Double(UInt16.max)
        let dynamic: String
        switch vel {
        case let v where v >= 0.9: dynamic = "\\ff"
        case let v where v >= 0.7: dynamic = "\\f"
        case let v where v >= 0.5: dynamic = "\\mf"
        case let v where v >= 0.3: dynamic = "\\p"
        default: dynamic = "\\pp"
        }

        let lily = """
        \\version "2.24.2"
        { \(dynamic) \(note) }
        """

        return LilyScore(lily)
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
