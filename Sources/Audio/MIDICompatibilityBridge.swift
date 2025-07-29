import Foundation

/// Provides downcasting of MIDI2NoteEvent to legacy formats for
/// Csound and LilyPond while maintaining MIDI 2.0 expressiveness.
public struct MIDICompatibilityBridge {
    public static func toMIDINote(_ event: MIDI2NoteEvent) -> MIDINote {
        MIDINote(
            channel: event.channel,
            note: event.note,
            velocity: Int(event.velocity * 127),
            duration: 0.1
        )
    }

    public static func toCsoundScore(_ event: MIDI2NoteEvent) -> CsoundScore {
        let frequency = 440.0 * pow(2.0, (Double(event.pitch) - 69.0) / 12.0)
        let amplitude = max(0.0, min(1.0, Double(event.velocity)))
        let start = Double(event.timestamp) / 1000.0
        let scoreLine = String(
            format: "i1 %.3f %.3f %.3f %.3f",
            start,
            0.1,
            frequency,
            amplitude
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

    public static func toLilyScore(_ event: MIDI2NoteEvent) -> LilyScore {
        let names = ["c", "cis", "d", "dis", "e", "f", "fis", "g", "gis", "a", "ais", "b"]
        let value = Int(round(event.pitch))
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

        let dynamic: String
        switch event.velocity {
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
