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

public struct UMPEncoder {
    public static func encode(_ note: MIDI2Note) -> [UInt32] {
        let status: UInt32 = 0x40 << 24 | UInt32(note.channel & 0xF) << 16
        let pitch = UInt32(note.note & 0x7F) << 8
        let velocity = UInt32(max(0, min(65535, Int(note.velocity * 65535))))
        let word1 = status | pitch | (velocity >> 8)
        let word2 = UInt32(velocity & 0xFF) << 24
        return [word1, word2]
    }
}
