import Foundation

/// Errors that can occur while parsing Universal MIDI Packet files.
enum UMPParserError: Error {
    case misaligned
}

/// Basic event representation for Universal MIDI Packets.
enum UMPEvent {
    case systemMessage(group: UInt8, status: UInt8, data1: UInt8, data2: UInt8)
    case midi1ChannelVoice(group: UInt8, channel: UInt8, status: UInt8, data1: UInt8, data2: UInt8)
    case unknown(group: UInt8, rawWords: [UInt32])
}

/// Parser for Universal MIDI Packet (UMP) files. This initial implementation
/// supports decoding system real-time/common messages and MIDI 1.0 channel voice
/// messages while preserving all other packet types as opaque data.
struct UMPParser {
    /// Parses a UMP-formatted data stream.
    /// - Parameter data: Raw bytes of the UMP file.
    /// - Returns: Array of decoded `UMPEvent` values.
    static func parse(data: Data) throws -> [UMPEvent] {
        guard data.count % 4 == 0 else { throw UMPParserError.misaligned }
        var events: [UMPEvent] = []
        var index = 0
        while index < data.count {
            let word = data[index..<(index + 4)].withUnsafeBytes { ptr -> UInt32 in
                return UInt32(bigEndian: ptr.load(as: UInt32.self))
            }
            let messageType = UInt8((word >> 28) & 0xF)
            let group = UInt8((word >> 24) & 0xF)
            let wordCount = packetLength(for: messageType)
            var words = [word]
            for i in 1..<wordCount {
                let w = data[(index + 4 * i)..<(index + 4 * (i + 1))].withUnsafeBytes { ptr -> UInt32 in
                    return UInt32(bigEndian: ptr.load(as: UInt32.self))
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

    /// Decodes a packet into a `UMPEvent`.
    private static func decode(messageType: UInt8, group: UInt8, words: [UInt32]) -> UMPEvent {
        switch messageType {
        case 0x1: // System Real-Time and System Common Messages
            let word = words[0]
            let status = UInt8((word >> 16) & 0xFF)
            let data1 = UInt8((word >> 8) & 0xFF)
            let data2 = UInt8(word & 0xFF)
            return .systemMessage(group: group, status: status, data1: data1, data2: data2)
        case 0x2: // MIDI 1.0 Channel Voice Messages
            let word = words[0]
            let status = UInt8(((word >> 20) & 0x0F) << 4)
            let channel = UInt8((word >> 16) & 0x0F)
            let data1 = UInt8((word >> 8) & 0x7F)
            let data2 = UInt8(word & 0x7F)
            return .midi1ChannelVoice(group: group, channel: channel, status: status, data1: data1, data2: data2)
        default:
            return .unknown(group: group, rawWords: words)
        }
    }
}
// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
