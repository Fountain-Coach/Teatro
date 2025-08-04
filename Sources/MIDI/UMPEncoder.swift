import Foundation

/// Encodes `MIDI2Note` values into Universal MIDI Packet words.
public struct UMPEncoder {
    /// Encodes a single note as a 64-bit MIDI 2.0 Note On packet.
    /// - Parameters:
    ///   - note: The note to encode. Velocity is scaled to 16-bit resolution.
    ///   - group: Optional UMP group number (0-15). Defaults to 0.
    /// - Returns: An array of two 32-bit words representing the packet.
    public static func encode(_ note: MIDI2Note, group: UInt8 = 0) -> [UInt32] {
        let messageType: UInt32 = 0x4 << 28 // MIDI 2.0 Channel Voice Message
        let groupBits = UInt32(group & 0xF) << 24
        let status: UInt32 = 0x9 << 20 // Note On opcode
        let channelBits = UInt32(note.channel & 0xF) << 16
        let noteBits = UInt32(note.note & 0x7F) << 8
        let word1 = messageType | groupBits | status | channelBits | noteBits

        let velocity = UInt32(max(0, min(0xFFFF, Int((note.velocity * 65535.0).rounded()))))
        let word2 = velocity << 16 // Attribute data unused
        return [word1, word2]
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
