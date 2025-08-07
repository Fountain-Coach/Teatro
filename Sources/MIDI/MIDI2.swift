import Foundation

/// Supported per-note attribute identifiers.
public enum MIDI2NoteAttribute: UInt8, CaseIterable, Sendable {
    /// No attribute data.
    case none = 0x00
    /// Manufacturer specific attribute data.
    case manufacturerSpecific = 0x01
    /// Profile specific attribute data.
    case profileSpecific = 0x02
    /// Pitch 7.9 attribute data.
    case pitch7_9 = 0x03
}

/// Lightweight representation of a MIDI 2.0 note event.
public struct MIDI2Note: Sendable, Equatable {
    public let channel: Int
    public let note: Int
    /// 32-bit velocity value.
    public let velocity: UInt32
    public let duration: Double
    public let pitchBend: UInt32?
    public let articulation: String?
    /// Optional per-note controllers.
    public let perNoteControllers: [PerNoteController]?
    /// Optional JR Timestamp preceding the note message.
    public let jrTimestamp: UInt32?
    /// Optional typed per-note attribute data.
    public let attributes: [MIDI2NoteAttribute: UInt32]?

    public init(channel: Int,
                note: Int,
                velocity: UInt32,
                duration: Double,
                pitchBend: UInt32? = nil,
                articulation: String? = nil,
                perNoteControllers: [PerNoteController]? = nil,
                jrTimestamp: UInt32? = nil,
                attributes: [MIDI2NoteAttribute: UInt32]? = nil) {
        self.channel = channel
        self.note = note
        self.velocity = velocity
        self.duration = duration
        self.pitchBend = pitchBend
        self.articulation = articulation
        self.perNoteControllers = perNoteControllers
        self.jrTimestamp = jrTimestamp
        self.attributes = attributes
    }

    /// Returns the attribute value for a given identifier.
    public func attribute(_ attribute: MIDI2NoteAttribute) -> UInt32? {
        attributes?[attribute]
    }

    /// Validates that all attributes use supported identifiers.
    public func validateAttributes() -> Bool {
        guard let attrs = attributes else { return true }
        return attrs.keys.allSatisfy { MIDI2NoteAttribute.allCases.contains($0) }
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
