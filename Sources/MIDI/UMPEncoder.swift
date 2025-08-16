import Foundation

/// Encodes MIDI 2.0 note events into Universal MIDI Packet words.
public struct UMPEncoder {
    /// Encodes a single Note On message.
    /// - Parameter note: MIDI 2.0 Note On event.
    /// - Returns: Two 32-bit words representing the packet.
    public static func encode(_ note: Midi2NoteOn) -> [UInt32] {
        let packet = note.ump()
        return [packet.word0, packet.word1]
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
            let bytes = [UInt8](data)
            let uses8Bit = bytes.contains { b in
                b > 0x7F && b != 0xF0 && b != 0xF7
            }
            if uses8Bit {
                return encodeSysEx8(data, group: event.group ?? defaultGroup)
            } else {
                return encodeSysEx7(data, group: event.group ?? defaultGroup)
            }
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

    /// Encodes a SysEx7 message using segmentation as defined in the
    /// MIDI 2.0 specification. Messages longer than six bytes are split
    /// into Start, Continue, and End packets.
    private static func encodeSysEx7(_ data: Data, group: UInt8) -> [UInt32] {
        let bytes = [UInt8](data)
        let maxChunk = 6
        var result: [UInt32] = []
        if bytes.count <= maxChunk {
            let chunk = pad(bytes, to: maxChunk)
            result.append(contentsOf: packSysEx7(status: 0x0, count: UInt8(bytes.count), chunk: chunk, group: group))
            return result
        }
        var index = 0
        let startChunk = pad(Array(bytes[0..<maxChunk]), to: maxChunk)
        result.append(contentsOf: packSysEx7(status: 0x1, count: UInt8(maxChunk), chunk: startChunk, group: group))
        index += maxChunk
        while bytes.count - index > maxChunk {
            let chunk = Array(bytes[index..<(index + maxChunk)])
            result.append(contentsOf: packSysEx7(status: 0x2, count: UInt8(maxChunk), chunk: chunk, group: group))
            index += maxChunk
        }
        let remaining = Array(bytes[index..<bytes.count])
        let endChunk = pad(remaining, to: maxChunk)
        result.append(contentsOf: packSysEx7(status: 0x3, count: UInt8(remaining.count), chunk: endChunk, group: group))
        return result
    }

    /// Encodes a SysEx8 message which can contain arbitrary 8-bit data.
    /// Follows the segmentation rules of M2-104-UM v1-1-2.
    private static func encodeSysEx8(_ data: Data, group: UInt8) -> [UInt32] {
        let bytes = [UInt8](data)
        let maxChunk = 10
        var result: [UInt32] = []
        if bytes.count <= maxChunk {
            let chunk = pad(bytes, to: maxChunk)
            result.append(contentsOf: packSysEx8(status: 0x0, count: UInt8(bytes.count), chunk: chunk, group: group))
            return result
        }
        var index = 0
        let startChunk = pad(Array(bytes[0..<maxChunk]), to: maxChunk)
        result.append(contentsOf: packSysEx8(status: 0x1, count: UInt8(maxChunk), chunk: startChunk, group: group))
        index += maxChunk
        while bytes.count - index > maxChunk {
            let chunk = Array(bytes[index..<(index + maxChunk)])
            result.append(contentsOf: packSysEx8(status: 0x2, count: UInt8(maxChunk), chunk: chunk, group: group))
            index += maxChunk
        }
        let remaining = Array(bytes[index..<bytes.count])
        let endChunk = pad(remaining, to: maxChunk)
        result.append(contentsOf: packSysEx8(status: 0x3, count: UInt8(remaining.count), chunk: endChunk, group: group))
        return result
    }

    /// Pads `bytes` with zeros up to `size` elements.
    private static func pad(_ bytes: [UInt8], to size: Int) -> [UInt8] {
        if bytes.count >= size { return Array(bytes[0..<size]) }
        return bytes + Array(repeating: 0, count: size - bytes.count)
    }

    /// Packs a SysEx7 chunk into two UMP words.
    private static func packSysEx7(status: UInt8, count: UInt8, chunk: [UInt8], group: UInt8) -> [UInt32] {
        let word1 = (UInt32(0x5) << 28)
            | (UInt32(group & 0xF) << 24)
            | (UInt32(status) << 20)
            | (UInt32(count) << 16)
            | (UInt32(chunk[0]) << 8)
            | UInt32(chunk[1])
        let word2 = (UInt32(chunk[2]) << 24)
            | (UInt32(chunk[3]) << 16)
            | (UInt32(chunk[4]) << 8)
            | UInt32(chunk[5])
        return [word1, word2]
    }

    /// Packs a SysEx8 chunk into three UMP words.
    private static func packSysEx8(status: UInt8, count: UInt8, chunk: [UInt8], group: UInt8) -> [UInt32] {
        let word1 = (UInt32(0x6) << 28)
            | (UInt32(group & 0xF) << 24)
            | (UInt32(status) << 20)
            | (UInt32(count) << 16)
            | (UInt32(chunk[0]) << 8)
            | UInt32(chunk[1])
        let word2 = (UInt32(chunk[2]) << 24)
            | (UInt32(chunk[3]) << 16)
            | (UInt32(chunk[4]) << 8)
            | UInt32(chunk[5])
        let word3 = (UInt32(chunk[6]) << 24)
            | (UInt32(chunk[7]) << 16)
            | (UInt32(chunk[8]) << 8)
            | UInt32(chunk[9])
        return [word1, word2, word3]
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
