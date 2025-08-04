import Foundation

public struct MIDI2Note: Sendable, Equatable {
    public let channel: Int
    public let note: Int
    public let velocity: Float // 0.0 - 1.0
    public let duration: Double
    public let pitchBend: Float?
    public let articulation: String?
    public let perNoteCC: [Int: Float]?

    public init(channel: Int, note: Int, velocity: Float, duration: Double, pitchBend: Float? = nil, articulation: String? = nil, perNoteCC: [Int: Float]? = nil) {
        self.channel = channel
        self.note = note
        self.velocity = velocity
        self.duration = duration
        self.pitchBend = pitchBend
        self.articulation = articulation
        self.perNoteCC = perNoteCC
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
