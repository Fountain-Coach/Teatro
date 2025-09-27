import Foundation

/// Represents a per-note pitch in MIDI 2.0.
public struct PerNotePitch: MidiEventProtocol, Sendable, Equatable {
    public let timestamp: UInt32
    public let group: UInt8?
    public let channel: UInt8?
    public let noteNumber: UInt8?
    /// 32-bit pitch value.
    public let pitch: UInt32

    public init(timestamp: UInt32 = 0,
                group: UInt8? = nil,
                channel: UInt8? = nil,
                noteNumber: UInt8?,
                pitch: UInt32) {
        self.timestamp = timestamp
        self.group = group
        self.channel = channel
        self.noteNumber = noteNumber
        self.pitch = pitch
    }

    public var type: MidiEventType { .perNotePitch }
    public var velocity: UInt32? { nil }
    public var controllerValue: UInt32? { pitch }
    public var metaType: UInt8? { nil }
    public var rawData: Data? { nil }

    /// Converts the 32-bit value to a 14-bit MIDI 1.0 pitch bend value.
    public var midi1Value: UInt16 {
        MIDI.midi1PitchBend(from: pitch)
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
