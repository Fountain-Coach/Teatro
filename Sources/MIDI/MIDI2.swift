import Foundation

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
    /// Placeholder for future per-note attribute data.
    public let attributes: [String: UInt32]?

    public init(channel: Int,
                note: Int,
                velocity: UInt32,
                duration: Double,
                pitchBend: UInt32? = nil,
                articulation: String? = nil,
                perNoteControllers: [PerNoteController]? = nil,
                jrTimestamp: UInt32? = nil,
                attributes: [String: UInt32]? = nil) {
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
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
