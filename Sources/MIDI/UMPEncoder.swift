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

    /// Encodes an array of `MidiEventProtocol` events into MIDI 1.0 channel voice
    /// UMP words.
    /// - Parameters:
    ///   - events: MIDI events to encode.
    ///   - defaultGroup: Group applied when an event does not specify one.
    /// - Returns: Array of 32-bit UMP words.
    public static func encodeEvents(_ events: [any MidiEventProtocol], defaultGroup: UInt8 = 0) -> [UInt32] {
        events.flatMap { encodeEvent($0, defaultGroup: defaultGroup) }
    }

    /// Encodes a single `MidiEventProtocol` into UMP words.
    /// - Parameters:
    ///   - event: The MIDI event to encode.
    ///   - defaultGroup: Group applied when the event lacks an explicit group.
    /// - Returns: Array of 32-bit UMP words.
    public static func encodeEvent(_ event: any MidiEventProtocol, defaultGroup: UInt8 = 0) -> [UInt32] {
        switch event.type {
        case .sysEx:
            guard let data = event.rawData else { return [] }
            return encodeSysEx7(data, group: event.group ?? defaultGroup)
        default:
            let messageType: UInt32 = 0x2 << 28 // MIDI 1.0 Channel Voice Message
            let groupBits = UInt32((event.group ?? defaultGroup) & 0xF) << 24
            guard let channel = event.channel else { return [] }
            let channelBits = UInt32(channel & 0xF) << 16

            func build(_ status: UInt32, _ data1: UInt32, _ data2: UInt32) -> UInt32 {
                messageType | groupBits | status | channelBits | (data1 << 8) | data2
            }

            switch event.type {
            case .noteOn:
                let status: UInt32 = 0x9 << 20
                let note = UInt32(event.noteNumber ?? 0)
                let vel = UInt32(event.velocity ?? 0)
                return [build(status, note, vel)]
            case .noteOff:
                let status: UInt32 = 0x8 << 20
                let note = UInt32(event.noteNumber ?? 0)
                let vel = UInt32(event.velocity ?? 0)
                return [build(status, note, vel)]
            case .polyphonicKeyPressure:
                let status: UInt32 = 0xA << 20
                let note = UInt32(event.noteNumber ?? 0)
                let pressure = UInt32(event.velocity ?? 0)
                return [build(status, note, pressure)]
            case .controlChange:
                let status: UInt32 = 0xB << 20
                let controller = UInt32(event.noteNumber ?? 0)
                let value = UInt32(event.controllerValue ?? 0)
                return [build(status, controller, value)]
            case .programChange:
                let status: UInt32 = 0xC << 20
                let program = UInt32(event.controllerValue ?? 0)
                return [build(status, program, 0)]
            case .channelPressure:
                let status: UInt32 = 0xD << 20
                let pressure = UInt32(event.controllerValue ?? 0)
                return [build(status, pressure, 0)]
            case .pitchBend:
                let status: UInt32 = 0xE << 20
                let value = UInt32(event.controllerValue ?? 0)
                let data1 = value & 0x7F
                let data2 = (value >> 7) & 0x7F
                return [build(status, data1, data2)]
            default:
                return []
            }
        }
    }

    /// Encodes a SysEx7 message into UMP words. Only a subset of the full
    /// specification is implemented, covering packets up to 6 bytes which are
    /// emitted as a single message type 0x5 packet.
    private static func encodeSysEx7(_ data: Data, group: UInt8) -> [UInt32] {
        var bytes = Array(data)
        while bytes.count < 6 { bytes.append(0) }
        let word1 = (0x5 << 28)
            | (UInt32(group & 0xF) << 24)
            | (UInt32(bytes[0]) << 16)
            | (UInt32(bytes[1]) << 8)
            | UInt32(bytes[2])
        let word2 = (UInt32(bytes[3]) << 24)
            | (UInt32(bytes[4]) << 16)
            | (UInt32(bytes[5]) << 8)
            | 0
        return [word1, word2]
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
