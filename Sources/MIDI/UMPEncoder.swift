import Foundation

/// Encodes `MIDI2Note` values into Universal MIDI Packet words.
public struct UMPEncoder {
    /// Encodes a single note as a MIDI 2.0 Note On packet.
    /// If a JR Timestamp is present it is emitted before the note message.
    /// - Parameters:
    ///   - note: The note to encode with full 32-bit velocity.
    ///   - group: Optional UMP group number (0-15). Defaults to 0.
    /// - Returns: An array of 32-bit words representing the packet(s).
    public static func encode(_ note: MIDI2Note, group: UInt8 = 0) -> [UInt32] {
        var words: [UInt32] = []
        if let ts = note.jrTimestamp {
            let tsWord = (0x1 << 28) | UInt32(ts & 0xFFFFFF)
            words.append(tsWord)
        }
        let messageType: UInt32 = 0x4 << 28 // MIDI 2.0 Channel Voice Message
        let groupBits = UInt32(group & 0xF) << 24
        let channelBits = UInt32(note.channel & 0xF) << 16
        let noteBits = UInt32(note.note & 0x7F) << 8

        if let controllers = note.perNoteControllers {
            for ctrl in controllers {
                let status: UInt32 = 0x0 << 20
                let word1 = messageType | groupBits | status | channelBits | noteBits | UInt32(ctrl.index)
                words.append(word1)
                words.append(ctrl.value)
            }
        }

        var remainingAttributes = note.attributes ?? [:]
        var primaryAttribute: (MIDI2NoteAttribute, UInt32)?
        if let first = remainingAttributes.first {
            primaryAttribute = first
            remainingAttributes.removeValue(forKey: first.key)
        }

        if !remainingAttributes.isEmpty {
            for (attr, value) in remainingAttributes {
                let status: UInt32 = 0xF << 20
                let word1 = messageType | groupBits | status | channelBits | noteBits | UInt32(attr.rawValue)
                words.append(word1)
                words.append(value)
            }
        }

        let status: UInt32 = 0x9 << 20 // Note On opcode
        if let primary = primaryAttribute {
            let word1 = messageType | groupBits | status | channelBits | noteBits | UInt32(primary.0.rawValue)
            let velocity = (note.velocity >> 16) & 0xFFFF
            let attrData = UInt16(primary.1 & 0xFFFF)
            let word2 = (velocity << 16) | UInt32(attrData)
            words.append(contentsOf: [word1, word2])
        } else {
            let word1 = messageType | groupBits | status | channelBits | noteBits
            let vel16 = (note.velocity >> 16) & 0xFFFF
            let word2 = (vel16 << 16)
            words.append(contentsOf: [word1, word2])
        }
        return words
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
        case .jrTimestamp:
            let messageType: UInt32 = 0x1 << 28
            let groupBits = UInt32((event.group ?? defaultGroup) & 0xF) << 24
            let value = (event.controllerValue ?? 0) & 0xFFFFFF
            return [messageType | groupBits | value]
        case .perNoteController:
            guard let ctrl = event as? PerNoteControllerEvent else { return [] }
            let messageType: UInt32 = 0x4 << 28
            let groupBits = UInt32((event.group ?? defaultGroup) & 0xF) << 24
            let channelBits = UInt32((event.channel ?? 0) & 0xF) << 16
            let noteBits = UInt32((event.noteNumber ?? 0) & 0x7F) << 8
            let word1 = messageType | groupBits | (0x0 << 20) | channelBits | noteBits | UInt32(ctrl.controllerIndex)
            return [word1, ctrl.controllerValue ?? 0]
        case .perNotePitchBend:
            guard let bend = event as? PerNotePitchBendEvent else { return [] }
            let messageType: UInt32 = 0x4 << 28
            let groupBits = UInt32((event.group ?? defaultGroup) & 0xF) << 24
            let channelBits = UInt32((event.channel ?? 0) & 0xF) << 16
            let noteBits = UInt32((event.noteNumber ?? 0) & 0x7F) << 8
            let word1 = messageType | groupBits | (0x2 << 20) | channelBits | noteBits
            return [word1, bend.pitch]
        case .rpn:
            guard let r = event as? RegisteredParameterNumber else { return [] }
            let messageType: UInt32 = 0x4 << 28
            let groupBits = UInt32((event.group ?? defaultGroup) & 0xF) << 24
            let channelBits = UInt32((event.channel ?? 0) & 0xF) << 16
            let msb = UInt32((r.parameter >> 7) & 0x7F)
            let lsb = UInt32(r.parameter & 0x7F)
            let word1 = messageType | groupBits | (0x6 << 20) | channelBits | (msb << 8) | lsb
            return [word1, r.value]
        case .nrpn:
            guard let n = event as? NonRegisteredParameterNumber else { return [] }
            let messageType: UInt32 = 0x4 << 28
            let groupBits = UInt32((event.group ?? defaultGroup) & 0xF) << 24
            let channelBits = UInt32((event.channel ?? 0) & 0xF) << 16
            let msb = UInt32((n.parameter >> 7) & 0x7F)
            let lsb = UInt32(n.parameter & 0x7F)
            let word1 = messageType | groupBits | (0x7 << 20) | channelBits | (msb << 8) | lsb
            return [word1, n.value]
        case .noteOnWithAttribute:
            guard let n = event as? NoteOnWithAttributeEvent, n.type != .unknown else { return [] }
            let messageType: UInt32 = 0x4 << 28
            let groupBits = UInt32((event.group ?? defaultGroup) & 0xF) << 24
            let channelBits = UInt32((event.channel ?? 0) & 0xF) << 16
            let noteBits = UInt32((event.noteNumber ?? 0) & 0x7F) << 8
            let word1 = messageType | groupBits | (0x9 << 20) | channelBits | noteBits | UInt32(n.attributeType.rawValue)
            let velocity = ((n.velocity ?? 0) >> 16) & 0xFFFF
            let word2 = (0x0 << 28) | (velocity << 16) | UInt32(n.attributeData)
            return [word1, word2]
        case .noteOffWithAttribute:
            guard let n = event as? NoteOffWithAttributeEvent, n.type != .unknown else { return [] }
            let messageType: UInt32 = 0x4 << 28
            let groupBits = UInt32((event.group ?? defaultGroup) & 0xF) << 24
            let channelBits = UInt32((event.channel ?? 0) & 0xF) << 16
            let noteBits = UInt32((event.noteNumber ?? 0) & 0x7F) << 8
            let word1 = messageType | groupBits | (0x8 << 20) | channelBits | noteBits | UInt32(n.attributeType.rawValue)
            let velocity = ((n.velocity ?? 0) >> 16) & 0xFFFF
            let word2 = (0x0 << 28) | (velocity << 16) | UInt32(n.attributeData)
            return [word1, word2]
        case .noteEnd:
            guard let n = event as? NoteEndEvent, n.type != .unknown else { return [] }
            let messageType: UInt32 = 0x4 << 28
            let groupBits = UInt32((event.group ?? defaultGroup) & 0xF) << 24
            let channelBits = UInt32((event.channel ?? 0) & 0xF) << 16
            let noteBits = UInt32((event.noteNumber ?? 0) & 0x7F) << 8
            let word1 = messageType | groupBits | (0x1 << 20) | channelBits | noteBits | UInt32(n.attributeType.rawValue)
            let velocity = ((n.velocity ?? 0) >> 16) & 0xFFFF
            let word2 = (velocity << 16) | UInt32(n.attributeData)
            return [word1, word2]
        case .pitchClamp:
            guard let p = event as? PitchClampEvent else { return [] }
            let messageType: UInt32 = 0x4 << 28
            let groupBits = UInt32((event.group ?? defaultGroup) & 0xF) << 24
            let channelBits = UInt32((event.channel ?? 0) & 0xF) << 16
            let noteBits = UInt32((event.noteNumber ?? 0) & 0x7F) << 8
            let word1 = messageType | groupBits | (0x1 << 20) | channelBits | noteBits
            let word2 = (0x2 << 28) | (p.pitch & 0x0FFFFFFF)
            return [word1, word2]
        case .pitchRelease:
            guard let _ = event as? PitchReleaseEvent else { return [] }
            let messageType: UInt32 = 0x4 << 28
            let groupBits = UInt32((event.group ?? defaultGroup) & 0xF) << 24
            let channelBits = UInt32((event.channel ?? 0) & 0xF) << 16
            let noteBits = UInt32((event.noteNumber ?? 0) & 0x7F) << 8
            let word1 = messageType | groupBits | (0x1 << 20) | channelBits | noteBits
            let word2: UInt32 = 0x3 << 28
            return [word1, word2]
        case .noteAttribute:
            guard let attr = event as? NoteAttributeEvent else { return [] }
            let messageType: UInt32 = 0x4 << 28
            let groupBits = UInt32((event.group ?? defaultGroup) & 0xF) << 24
            let channelBits = UInt32((event.channel ?? 0) & 0xF) << 16
            let noteBits = UInt32((event.noteNumber ?? 0) & 0x7F) << 8
            let word1 = messageType | groupBits | (0xF << 20) | channelBits | noteBits | UInt32(attr.attributeIndex)
            return [word1, attr.attributeValue]
        default:
            guard let channel = event.channel else { return [] }
            let controllerThreshold: UInt32 = event.type == .pitchBend ? 0x3FFF : 0x7F
            let isMIDI2 = (event.velocity ?? 0) > 0x7F || (event.controllerValue ?? 0) > controllerThreshold
            let groupBits = UInt32((event.group ?? defaultGroup) & 0xF) << 24
            let channelBits = UInt32(channel & 0xF) << 16
            if isMIDI2 {
                let messageType: UInt32 = 0x4 << 28
                switch event.type {
                case .noteOn:
                    let status: UInt32 = 0x9 << 20
                    let noteBits = UInt32(event.noteNumber ?? 0) << 8
                    let word1 = messageType | groupBits | status | channelBits | noteBits
                    return [word1, event.velocity ?? 0]
                case .noteOff:
                    let status: UInt32 = 0x8 << 20
                    let noteBits = UInt32(event.noteNumber ?? 0) << 8
                    let word1 = messageType | groupBits | status | channelBits | noteBits
                    return [word1, event.velocity ?? 0]
                case .polyphonicKeyPressure:
                    let status: UInt32 = 0xA << 20
                    let noteBits = UInt32(event.noteNumber ?? 0) << 8
                    let word1 = messageType | groupBits | status | channelBits | noteBits
                    return [word1, event.velocity ?? 0]
                case .controlChange:
                    let status: UInt32 = 0xB << 20
                    let controller = UInt32(event.noteNumber ?? 0) << 8
                    let word1 = messageType | groupBits | status | channelBits | controller
                    return [word1, event.controllerValue ?? 0]
                case .channelPressure:
                    let status: UInt32 = 0xD << 20
                    let word1 = messageType | groupBits | status | channelBits
                    return [word1, event.controllerValue ?? 0]
                case .pitchBend:
                    let status: UInt32 = 0xE << 20
                    let word1 = messageType | groupBits | status | channelBits
                    return [word1, event.controllerValue ?? 0]
                default:
                    return []
                }
            } else {
                let messageType: UInt32 = 0x2 << 28
                func build(_ status: UInt32, _ data1: UInt32, _ data2: UInt32) -> UInt32 {
                    messageType | groupBits | status | channelBits | (data1 << 8) | data2
                }
                switch event.type {
                case .noteOn:
                    let status: UInt32 = 0x9 << 20
                    let note = UInt32(event.noteNumber ?? 0)
                    let raw = event.velocity ?? 0
                    let vel = raw > 0x7F ? UInt32(MIDI.midi1Velocity(from: raw)) : raw
                    return [build(status, note, vel)]
                case .noteOff:
                    let status: UInt32 = 0x8 << 20
                    let note = UInt32(event.noteNumber ?? 0)
                    let raw = event.velocity ?? 0
                    let vel = raw > 0x7F ? UInt32(MIDI.midi1Velocity(from: raw)) : raw
                    return [build(status, note, vel)]
                case .polyphonicKeyPressure:
                    let status: UInt32 = 0xA << 20
                    let note = UInt32(event.noteNumber ?? 0)
                    let raw = event.velocity ?? 0
                    let pressure = raw > 0x7F ? UInt32(MIDI.midi1Velocity(from: raw)) : raw
                    return [build(status, note, pressure)]
                case .controlChange:
                    let status: UInt32 = 0xB << 20
                    let controller = UInt32(event.noteNumber ?? 0)
                    let raw = event.controllerValue ?? 0
                    let value = raw > 0x7F ? UInt32(MIDI.midi1Controller(from: raw)) : raw
                    return [build(status, controller, value)]
                case .programChange:
                    let status: UInt32 = 0xC << 20
                    let raw = event.controllerValue ?? 0
                    let program = raw > 0x7F ? UInt32(MIDI.midi1Controller(from: raw)) : raw
                    return [build(status, program, 0)]
                case .channelPressure:
                    let status: UInt32 = 0xD << 20
                    let raw = event.controllerValue ?? 0
                    let pressure = raw > 0x7F ? UInt32(MIDI.midi1Controller(from: raw)) : raw
                    return [build(status, pressure, 0)]
                case .pitchBend:
                    let status: UInt32 = 0xE << 20
                    let raw = event.controllerValue ?? 0
                    let bend = raw > 0x3FFF ? raw >> 18 : raw
                    let data1 = bend & 0x7F
                    let data2 = (bend >> 7) & 0x7F
                    return [build(status, data1, data2)]
                default:
                    return []
                }
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
