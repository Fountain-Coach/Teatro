import Foundation
import MIDI2

// Refs: teatro-root

/// Unified representation of Universal MIDI Packets used by Teatro.
/// This facade wraps packet types from `Fountain-Coach/midi2` and provides
/// a stable surface for future integration.
public enum UMPEvent {
    case channelVoice(Midi2ChannelVoiceBody)
    case utility(UtilityBody)
    case systemExclusive7(SysEx7Packet)
    case systemExclusive8(UmpPacket128)
    case flexEnvelope(FlexEnvelope)

    /// Creates a `UMPEvent` by parsing raw 32-bit words.
    /// Returns `nil` if the words do not encode a recognised packet type.
    public init?(words: [UInt32]) {
        guard let first = words.first else { return nil }
        let mt = UInt8((first >> 28) & 0xF)
        switch mt {
        case 0x0:
            let packet = UmpPacket32(word: first)
            guard let body = UtilityBody(ump: packet) else { return nil }
            self = .utility(body)
        case 0x4:
            guard let packet = UmpPacket64(words: words),
                  let body = Midi2ChannelVoiceBody(ump: packet) else { return nil }
            self = .channelVoice(body)
        case 0x5:
            guard let pkt = UmpPacket64(words: words),
                  let packet = SysEx7Packet(ump: pkt) else { return nil }
            self = .systemExclusive7(packet)
        case 0x6:
            guard let packet = UmpPacket128(words: words) else { return nil }
            self = .systemExclusive8(packet)
        default:
            return nil
        }
    }

    /// Raw 32-bit words backing the event.
    public var words: [UInt32] {
        switch self {
        case .utility(let body):
            return [body.ump().word]
        case .channelVoice(let body):
            return body.ump().words
        case .systemExclusive7(let packet):
            return packet.ump.words
        case .systemExclusive8(let packet):
            return packet.words
        case .flexEnvelope:
            return []
        }
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.

