import Foundation

/// Rich MIDI 2.0 event representation used by compatibility helpers.
public struct MIDI2NoteEvent: Sendable, Equatable {
    public var channel: Int
    public var note: Int
    public var velocity: Float
    public var pitch: Float
    public var timbre: SIMD4<Float>
    public var articulation: String
    public var timestamp: UInt64

    public init(channel: Int, note: Int, velocity: Float, pitch: Float,
                timbre: SIMD4<Float>, articulation: String, timestamp: UInt64) {
        self.channel = channel
        self.note = note
        self.velocity = velocity
        self.pitch = pitch
        self.timbre = timbre
        self.articulation = articulation
        self.timestamp = timestamp
    }
}
