import Foundation

public struct MIDINote {
    public let channel: Int
    public let note: Int
    public let velocity: Int
    public let duration: Double

    public init(channel: Int, note: Int, velocity: Int, duration: Double) {
        self.channel = channel
        self.note = note
        self.velocity = velocity
        self.duration = duration
    }
}

@resultBuilder
public enum NoteBuilder {
    public static func buildBlock(_ notes: MIDINote...) -> [MIDINote] {
        notes
    }
}

public struct MIDISequence: Renderable {
    public let notes: [MIDINote]

    public init(@NoteBuilder _ build: () -> [MIDINote]) {
        self.notes = build()
    }

    public func layout() -> LayoutNode {
        let lines = notes.map {
            "NOTE(ch:\($0.channel), key:\($0.note), vel:\($0.velocity), dur:\($0.duration))"
        }.joined(separator: "\n")
        return .raw(lines)
    }
}

public struct MIDIRenderer: RendererPlugin {
    public static let identifier = "midi"
    public static let fileExtensions = ["mid", "midi"]

    public static func renderToFile(_ sequence: MIDISequence, to path: String = "output.mid") {
        let content = sequence.notes.map {
            "NOTE(ch:\($0.channel), key:\($0.note), vel:\($0.velocity), dur:\($0.duration))"
        }.joined(separator: "\n")
        try? content.write(toFile: path, atomically: true, encoding: .utf8)
    }

    public static func render(view: Renderable, output: String?) throws {
        guard let seq = view as? MIDISequence else { throw RendererError.unsupportedInput("MIDI output requires a MIDISequence input") }
        renderToFile(seq, to: output ?? "output.mid")
    }
}

/// Convenience helpers for working with MIDI-CI SysEx messages.
public enum MIDI {
    /// Parses a MIDI-CI message from raw SysEx data.
    /// - Parameter data: Complete SysEx byte stream including `F0` and `F7`.
    /// - Returns: A typed `MIDICIMessage` if the packet conforms to MIDI-CI.
    public static func parseCIMessage(from data: Data) -> MIDICIMessage? {
        MIDICI.parse(sysEx: data)
    }

    /// Serializes a MIDI-CI message into a SysEx byte stream.
    /// - Parameter message: The message to encode.
    /// - Returns: Raw SysEx data including start/end markers.
    public static func sysEx(for message: MIDICIMessage) -> Data {
        MIDICI.serialize(message)
    }

    /// Converts a 32-bit MIDI 2.0 value to a MIDI 1.0 velocity (0-127).
    public static func midi1Velocity(from value: UInt32) -> UInt8 {
        if value <= 0x7F { return UInt8(truncatingIfNeeded: value) }
        if (value & 0x00FF_0000) != 0 {
            return UInt8(truncatingIfNeeded: value >> 25)
        } else {
            return UInt8(truncatingIfNeeded: value >> 24)
        }
    }

    /// Converts a 32-bit MIDI 2.0 controller value to a MIDI 1.0 7-bit value.
    public static func midi1Controller(from value: UInt32) -> UInt8 {
        if value <= 0x7F { return UInt8(truncatingIfNeeded: value) }
        if (value & 0x00FF_0000) != 0 {
            return UInt8(truncatingIfNeeded: value >> 25)
        } else {
            return UInt8(truncatingIfNeeded: value >> 24)
        }
    }

    /// Maps a MIDI 1.0 velocity byte into a 32-bit MIDI 2.0 value.
    public static func midi2Velocity(from value: UInt8) -> UInt32 {
        UInt32(value) << 25
    }

    /// Maps a MIDI 1.0 controller byte into a 32-bit MIDI 2.0 value.
    public static func midi2Controller(from value: UInt8) -> UInt32 {
        UInt32(value) << 25
    }

    /// Converts a 32-bit MIDI 2.0 pitch bend into the 14-bit MIDI 1.0 domain.
    public static func midi1PitchBend(from value: UInt32) -> UInt16 {
        UInt16(truncatingIfNeeded: value >> 18)
    }

    /// Expands a 14-bit MIDI 1.0 pitch bend value to 32-bit MIDI 2.0.
    public static func midi2PitchBend(from value: UInt16) -> UInt32 {
        UInt32(value) << 18
    }

    /// Wraps a raw SysEx payload with start/end markers for MIDI 1.0.
    public static func midi1SysEx(from payload: Data) -> Data {
        var bytes: [UInt8] = [0xF0]
        bytes.append(contentsOf: payload)
        bytes.append(0xF7)
        return Data(bytes)
    }

    /// Extracts the payload from a MIDI 1.0 SysEx message.
    public static func midi2SysExPayload(from data: Data) -> Data {
        var bytes = Array(data)
        if bytes.first == 0xF0 { bytes.removeFirst() }
        if bytes.last == 0xF7 { bytes.removeLast() }
        return Data(bytes)
    }

    /// Normalizes a 32-bit MIDI 2.0 value to a floating point range 0.0-1.0.
    public static func normalizedFloat(from value: UInt32) -> Float {
        Float(value) / Float(UInt32.max)
    }

    /// Convenience to scale a unit float into a 32-bit MIDI 2.0 value.
    public static func fromUnitFloat(_ value: Float) -> UInt32 {
        let clamped = max(0.0, min(1.0, value))
        if clamped >= 1.0 { return UInt32.max }
        let scaled = Double(clamped) * Double(UInt32.max)
        return UInt32(scaled)
    }
}
