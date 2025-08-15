import Foundation

/// Represents a per-note controller value in MIDI 2.0.
@available(*, deprecated, message: "Use `Midi2RegPerNoteController` from the MIDI2 module")
public struct PerNoteController: Sendable, Equatable {
    /// Controller index as defined by the MIDI 2.0 specification.
    public let index: UInt8
    /// 32-bit controller data value.
    public let value: UInt32

    public init(index: UInt8, value: UInt32) {
        self.index = index
        self.value = value
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
