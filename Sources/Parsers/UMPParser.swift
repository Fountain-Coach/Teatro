import Foundation

/// Errors that can occur while parsing Universal MIDI Packet files.
public enum UMPParserError: Error {
    case misaligned
    case truncated
}

/// Parser for Universal MIDI Packet (UMP) files. This implementation supports
/// decoding utility, system real-time/common, MIDI 1.0 channel voice, and MIDI
/// 2.0 channel voice messages while preserving all other packet types as opaque
/// data.
public struct UMPParser {
    /// Parses a UMP-formatted data stream.
    /// - Parameter data: Raw bytes of the UMP file.
    /// - Returns: Array of decoded `MidiEventProtocol` values.
    public static func parse(data: Data) throws -> [any MidiEventProtocol] {
        guard data.count % 4 == 0 else { throw UMPParserError.misaligned }
        var events: [any MidiEventProtocol] = []
        var index = 0
        var currentTimestamp: UInt32 = 0
        while index < data.count {
            let word = data[index..<(index + 4)].withUnsafeBytes { ptr -> UInt32 in
                UInt32(bigEndian: ptr.load(as: UInt32.self))
            }
            let messageType = UInt8((word >> 28) & 0xF)
            let group = UInt8((word >> 24) & 0xF)
            let wordCount = packetLength(for: messageType)
            guard index + wordCount * 4 <= data.count else {
                throw UMPParserError.truncated
            }
            var words = [word]
            for i in 1..<wordCount {
                let w = data[(index + 4 * i)..<(index + 4 * (i + 1))].withUnsafeBytes { ptr -> UInt32 in
                    UInt32(bigEndian: ptr.load(as: UInt32.self))
                }
                words.append(w)
            }
            if messageType == 0x1 {
                let value = words[0] & 0xFFFFFF
                events.append(JRTimestampEvent(timestamp: 0, group: group, value: value))
                currentTimestamp = value
            } else {
                events.append(decode(messageType: messageType, group: group, words: words, timestamp: currentTimestamp))
            }
            index += wordCount * 4
        }
        return events
    }

    /// Determines the number of 32-bit words for a packet based on message type.
    private static func packetLength(for messageType: UInt8) -> Int {
        switch messageType {
        case 0x0, 0x1, 0x2: return 1
        case 0x4, 0x5: return 2
        case 0x6: return 3
        case 0x7: return 4
        default: return 1
        }
    }

    /// Decodes a packet into a `MidiEventProtocol`.
    private static func decode(messageType: UInt8, group: UInt8, words: [UInt32], timestamp: UInt32) -> any MidiEventProtocol {
        switch messageType {
        case 0x2: // MIDI 1.0 Channel Voice Messages
            let word = words[0]
            let status = UInt8(((word >> 20) & 0x0F) << 4)
            let channel = UInt8((word >> 16) & 0x0F)
            let data1 = UInt8((word >> 8) & 0x7F)
            let data2 = UInt8(word & 0x7F)
            switch status {
            case 0x80:
                return ChannelVoiceEvent(timestamp: timestamp, type: .noteOff, group: group, channel: channel, noteNumber: data1, velocity: UInt32(data2), controllerValue: nil)
            case 0x90:
                let eventType: MidiEventType = data2 == 0 ? .noteOff : .noteOn
                return ChannelVoiceEvent(timestamp: timestamp, type: eventType, group: group, channel: channel, noteNumber: data1, velocity: UInt32(data2), controllerValue: nil)
            case 0xA0:
                return ChannelVoiceEvent(timestamp: timestamp, type: .polyphonicKeyPressure, group: group, channel: channel, noteNumber: data1, velocity: UInt32(data2), controllerValue: nil)
            case 0xB0:
                return ChannelVoiceEvent(timestamp: timestamp, type: .controlChange, group: group, channel: channel, noteNumber: data1, velocity: nil, controllerValue: UInt32(data2))
            case 0xC0:
                return ChannelVoiceEvent(timestamp: timestamp, type: .programChange, group: group, channel: channel, noteNumber: nil, velocity: nil, controllerValue: UInt32(data1))
            case 0xE0:
                let value = UInt32((UInt16(data2) << 7) | UInt16(data1))
                return ChannelVoiceEvent(timestamp: timestamp, type: .pitchBend, group: group, channel: channel, noteNumber: nil, velocity: nil, controllerValue: value)
            case 0xD0:
                return ChannelVoiceEvent(timestamp: timestamp, type: .channelPressure, group: group, channel: channel, noteNumber: nil, velocity: nil, controllerValue: UInt32(data1))
            default:
                return UnknownEvent(timestamp: timestamp, data: rawData(from: words), group: group)
            }
        case 0x4: // MIDI 2.0 Channel Voice Messages
            let word1 = words[0]
            let status = UInt8(((word1 >> 20) & 0x0F) << 4)
            let channel = UInt8((word1 >> 16) & 0x0F)
            let data1 = UInt16(word1 & 0xFFFF)
            let data2 = words.count > 1 ? words[1] : 0
            switch status {
            case 0x80:
                let note = UInt8((data1 >> 8) & 0xFF)
                let attr = UInt8(data1 & 0xFF)
                let attrData = UInt16(data2 & 0xFFFF)
                if attr == 0 && attrData == 0 {
                    let vel = data2
                    return ChannelVoiceEvent(timestamp: timestamp, type: .noteOff, group: group, channel: channel, noteNumber: note, velocity: vel, controllerValue: nil)
                } else {
                    let vel = UInt32((data2 >> 16) & 0xFFFF) << 16
                    return NoteOffWithAttributeEvent(timestamp: timestamp, group: group, channel: channel, noteNumber: note, velocity: vel, attributeType: attr, attributeData: attrData)
                }
            case 0x90:
                let note = UInt8((data1 >> 8) & 0xFF)
                let attr = UInt8(data1 & 0xFF)
                let attrData = UInt16(data2 & 0xFFFF)
                if attr == 0 && attrData == 0 {
                    let vel = data2
                    let eventType: MidiEventType = vel == 0 ? .noteOff : .noteOn
                    return ChannelVoiceEvent(timestamp: timestamp, type: eventType, group: group, channel: channel, noteNumber: note, velocity: vel, controllerValue: nil)
                } else {
                    let vel = UInt32((data2 >> 16) & 0xFFFF) << 16
                    return NoteOnWithAttributeEvent(timestamp: timestamp, group: group, channel: channel, noteNumber: note, velocity: vel, attributeType: attr, attributeData: attrData)
                }
            case 0xA0:
                let note = UInt8((data1 >> 8) & 0xFF)
                return ChannelVoiceEvent(timestamp: timestamp, type: .polyphonicKeyPressure, group: group, channel: channel, noteNumber: note, velocity: data2, controllerValue: nil)
            case 0xB0:
                let controller = UInt8((data1 >> 8) & 0xFF)
                return ChannelVoiceEvent(timestamp: timestamp, type: .controlChange, group: group, channel: channel, noteNumber: controller, velocity: nil, controllerValue: data2)
            case 0xC0:
                let program = UInt8((data2 >> 24) & 0x7F)
                return ChannelVoiceEvent(timestamp: timestamp, type: .programChange, group: group, channel: channel, noteNumber: nil, velocity: nil, controllerValue: UInt32(program))
            case 0xD0:
                return ChannelVoiceEvent(timestamp: timestamp, type: .channelPressure, group: group, channel: channel, noteNumber: nil, velocity: nil, controllerValue: data2)
            case 0xE0:
                return ChannelVoiceEvent(timestamp: timestamp, type: .pitchBend, group: group, channel: channel, noteNumber: nil, velocity: nil, controllerValue: data2)
            case let s where (s & 0xF0) == 0x10:
                guard words.count > 1 else {
                    return UnknownEvent(timestamp: timestamp, data: rawData(from: words), group: group)
                }
                let note = UInt8((data1 >> 8) & 0xFF)
                let attr = UInt8(data1 & 0xFF)
                let word2 = words[1]
                let subtype = UInt8((word2 >> 28) & 0xF)
                switch subtype {
                case 0x0:
                    let velocity = UInt32((word2 >> 16) & 0xFFFF) << 16
                    let attributeData = UInt16(word2 & 0xFFFF)
                    return NoteEndEvent(
                        timestamp: timestamp,
                        group: group,
                        channel: channel,
                        noteNumber: note,
                        velocity: velocity,
                        attributeType: attr,
                        attributeData: attributeData
                    )
                case 0x2:
                    let pitch = word2 & 0x0FFFFFFF
                    return PitchClampEvent(
                        timestamp: timestamp,
                        group: group,
                        channel: channel,
                        noteNumber: note,
                        pitch: pitch
                    )
                case 0x3:
                    return PitchReleaseEvent(
                        timestamp: timestamp,
                        group: group,
                        channel: channel,
                        noteNumber: note
                    )
                default:
                    return UnknownEvent(timestamp: timestamp, data: rawData(from: words), group: group)
                }
            case 0x00:
                let note = UInt8((data1 >> 8) & 0xFF)
                let index = UInt8(data1 & 0xFF)
                return PerNoteControllerEvent(timestamp: timestamp, group: group, channel: channel, noteNumber: note, controllerIndex: index, controllerValue: data2)
            case 0xF0:
                let note = UInt8((data1 >> 8) & 0xFF)
                let index = UInt8(data1 & 0xFF)
                return NoteAttributeEvent(timestamp: timestamp, group: group, channel: channel, noteNumber: note, attributeIndex: index, attributeValue: data2)
            default:
                return UnknownEvent(timestamp: timestamp, data: rawData(from: words), group: group)
            }
        case 0x5, 0x6: // SysEx7 and SysEx8
            return SysExEvent(timestamp: timestamp, data: rawData(from: words), group: group)
        default:
            return UnknownEvent(timestamp: timestamp, data: rawData(from: words), group: group)
        }
    }

    /// Converts UMP words into raw data bytes.
    private static func rawData(from words: [UInt32]) -> Data {
        var bytes: [UInt8] = []
        for word in words {
            bytes.append(UInt8((word >> 24) & 0xFF))
            bytes.append(UInt8((word >> 16) & 0xFF))
            bytes.append(UInt8((word >> 8) & 0xFF))
            bytes.append(UInt8(word & 0xFF))
        }
        return Data(bytes)
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
