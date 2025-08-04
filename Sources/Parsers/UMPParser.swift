import Foundation

/// Errors that can occur while parsing Universal MIDI Packet files.
enum UMPParserError: Error {
    case misaligned
    case truncated
}

/// Parser for Universal MIDI Packet (UMP) files. This implementation supports
/// decoding utility, system real-time/common, MIDI 1.0 channel voice, and MIDI
/// 2.0 channel voice messages while preserving all other packet types as opaque
/// data.
struct UMPParser {
    /// Parses a UMP-formatted data stream.
    /// - Parameter data: Raw bytes of the UMP file.
    /// - Returns: Array of decoded `MidiEventProtocol` values.
    static func parse(data: Data) throws -> [any MidiEventProtocol] {
        guard data.count % 4 == 0 else { throw UMPParserError.misaligned }
        var events: [any MidiEventProtocol] = []
        var index = 0
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
            events.append(decode(messageType: messageType, group: group, words: words))
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
    private static func decode(messageType: UInt8, group: UInt8, words: [UInt32]) -> any MidiEventProtocol {
        switch messageType {
        case 0x2: // MIDI 1.0 Channel Voice Messages
            let word = words[0]
            let status = UInt8(((word >> 20) & 0x0F) << 4)
            let channel = UInt8((group << 4) | UInt8((word >> 16) & 0x0F))
            let data1 = UInt8((word >> 8) & 0x7F)
            let data2 = UInt8(word & 0x7F)
            switch status {
            case 0x80:
                return ChannelVoiceEvent(timestamp: 0, type: .noteOff, channelNumber: channel, noteNumber: data1, velocity: data2, controllerValue: nil)
            case 0x90:
                return ChannelVoiceEvent(timestamp: 0, type: .noteOn, channelNumber: channel, noteNumber: data1, velocity: data2, controllerValue: nil)
            case 0xA0:
                return ChannelVoiceEvent(timestamp: 0, type: .polyphonicKeyPressure, channelNumber: channel, noteNumber: data1, velocity: data2, controllerValue: nil)
            case 0xB0:
                return ChannelVoiceEvent(timestamp: 0, type: .controlChange, channelNumber: channel, noteNumber: data1, velocity: nil, controllerValue: UInt32(data2))
            case 0xC0:
                return ChannelVoiceEvent(timestamp: 0, type: .programChange, channelNumber: channel, noteNumber: nil, velocity: nil, controllerValue: UInt32(data1))
            case 0xE0:
                let value = UInt32((UInt16(data2) << 7) | UInt16(data1))
                return ChannelVoiceEvent(timestamp: 0, type: .pitchBend, channelNumber: channel, noteNumber: nil, velocity: nil, controllerValue: value)
            case 0xD0:
                return ChannelVoiceEvent(timestamp: 0, type: .channelPressure, channelNumber: channel, noteNumber: nil, velocity: nil, controllerValue: UInt32(data1))
            default:
                return UnknownEvent(timestamp: 0, data: rawData(from: words))
            }
        case 0x4: // MIDI 2.0 Channel Voice Messages
            let word1 = words[0]
            let status = UInt8(((word1 >> 20) & 0x0F) << 4)
            let channel = UInt8((group << 4) | UInt8((word1 >> 16) & 0x0F))
            let data1 = UInt16(word1 & 0xFFFF)
            let data2 = words.count > 1 ? words[1] : 0
            switch status {
            case 0x80:
                let note = UInt8((data1 >> 8) & 0xFF)
                let vel = ChannelVoiceEvent.normalizeVelocity(UInt16((data2 >> 16) & 0xFFFF))
                return ChannelVoiceEvent(timestamp: 0, type: .noteOff, channelNumber: channel, noteNumber: note, velocity: vel, controllerValue: nil)
            case 0x90:
                let note = UInt8((data1 >> 8) & 0xFF)
                let vel = ChannelVoiceEvent.normalizeVelocity(UInt16((data2 >> 16) & 0xFFFF))
                return ChannelVoiceEvent(timestamp: 0, type: .noteOn, channelNumber: channel, noteNumber: note, velocity: vel, controllerValue: nil)
            case 0xA0:
                let note = UInt8((data1 >> 8) & 0xFF)
                let pressure = ChannelVoiceEvent.normalizeController(data2)
                return ChannelVoiceEvent(timestamp: 0, type: .polyphonicKeyPressure, channelNumber: channel, noteNumber: note, velocity: pressure, controllerValue: nil)
            case 0xB0:
                let controller = UInt8((data1 >> 8) & 0xFF)
                let value = ChannelVoiceEvent.normalizeController(data2)
                return ChannelVoiceEvent(timestamp: 0, type: .controlChange, channelNumber: channel, noteNumber: controller, velocity: nil, controllerValue: UInt32(value))
            case 0xC0:
                let program = UInt8((data2 >> 24) & 0x7F)
                return ChannelVoiceEvent(timestamp: 0, type: .programChange, channelNumber: channel, noteNumber: nil, velocity: nil, controllerValue: UInt32(program))
            case 0xD0:
                return ChannelVoiceEvent(timestamp: 0, type: .channelPressure, channelNumber: channel, noteNumber: nil, velocity: nil, controllerValue: data2)
            case 0xE0:
                return ChannelVoiceEvent(timestamp: 0, type: .pitchBend, channelNumber: channel, noteNumber: nil, velocity: nil, controllerValue: data2)
            default:
                return UnknownEvent(timestamp: 0, data: rawData(from: words))
            }
        case 0x5, 0x6: // SysEx7 and SysEx8
            return SysExEvent(timestamp: 0, data: rawData(from: words))
        default:
            return UnknownEvent(timestamp: 0, data: rawData(from: words))
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
