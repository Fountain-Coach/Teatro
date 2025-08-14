import Foundation
import MIDI2

// Refs: teatro-root

/// Bridges between Universal MIDI Packets and MIDI 1.0 byte streams.
/// Only channel voice and basic SysEx7 messages are translated. Other
/// packet types are silently ignored so that unsupported data does not
/// terminate the conversion.
public enum MIDI1Bridge {
    /// Converts a stream of UMP data into a MIDI 1.0 byte sequence.
    /// - Parameter data: Raw UMP word bytes (big-endian).
    /// - Returns: MIDI 1.0 bytes. Unsupported messages are discarded.
    public static func umpToMIDI1(_ data: Data) throws -> Data {
        var bytes: [UInt8] = []
        let raw = [UInt8](data)
        var index = 0
        while index + 4 <= raw.count {
            let word0 = UInt32(raw[index]) << 24 |
                        UInt32(raw[index + 1]) << 16 |
                        UInt32(raw[index + 2]) << 8 |
                        UInt32(raw[index + 3])
            let mt = UInt8((word0 >> 28) & 0xF)
            let count: Int
            switch mt {
            case 0x0, 0x1, 0x2: count = 1
            case 0x4, 0x5: count = 2
            case 0x6: count = 3
            case 0x7: count = 4
            default: count = 1
            }
            guard index + count * 4 <= raw.count else { break }
            var words = [word0]
            for i in 1..<count {
                let base = index + i * 4
                let w = UInt32(raw[base]) << 24 |
                        UInt32(raw[base + 1]) << 16 |
                        UInt32(raw[base + 2]) << 8 |
                        UInt32(raw[base + 3])
                words.append(w)
            }
            index += count * 4
            guard let event = UMPEvent(words: words) else { continue }
            switch event {
            case .channelVoice(let body):
                let ch = UInt8(body.channel.rawValue)
                guard let variant = body.variant() else { continue }
                switch variant {
                case .noteOn(let msg):
                    let note = UInt8(msg.note.rawValue)
                    let vel32 = UInt32(msg.velocity) << 16
                    let vel7 = MIDI.midi1Velocity(from: vel32)
                    if vel7 == 0 {
                        bytes.append(0x80 | ch)
                        bytes.append(note)
                        bytes.append(0)
                    } else {
                        bytes.append(0x90 | ch)
                        bytes.append(note)
                        bytes.append(vel7)
                    }
                case .noteOff(let msg):
                    let note = UInt8(msg.noteNumber.rawValue)
                    let vel32 = UInt32(msg.velocity) << 16
                    let vel7 = MIDI.midi1Velocity(from: vel32)
                    bytes.append(0x80 | ch)
                    bytes.append(note)
                    bytes.append(vel7)
                case .controlChange(let msg):
                    bytes.append(0xB0 | ch)
                    bytes.append(UInt8(msg.control.rawValue))
                    bytes.append(MIDI.midi1Controller(from: msg.value))
                case .pitchBend(let msg):
                    let bend = MIDI.midi1PitchBend(from: msg.value)
                    bytes.append(0xE0 | ch)
                    bytes.append(UInt8(truncatingIfNeeded: bend & 0x7F))
                    bytes.append(UInt8(truncatingIfNeeded: bend >> 7))
                default:
                    continue
                }
            default:
                continue
            }
        }
        return Data(bytes)
    }

    /// Converts a MIDI 1.0 byte stream into UMP packets.
    /// - Parameters:
    ///   - data: MIDI 1.0 bytes.
    ///   - group: UMP group number applied to emitted packets.
    /// - Returns: Array of 32-bit UMP words.
    public static func midi1ToUMP(_ data: Data, group: UInt8 = 0) -> [UInt32] {
        var events: [any MidiEventProtocol] = []
        let bytes = Array(data)
        var i = 0
        var runningStatus: UInt8 = 0
        while i < bytes.count {
            var status = bytes[i]
            if status < 0x80 {
                status = runningStatus
            } else {
                runningStatus = status
                i += 1
            }
            let type = status & 0xF0
            let channel = status & 0x0F
            switch type {
            case 0x80, 0x90, 0xA0, 0xB0, 0xE0:
                guard i + 2 <= bytes.count else { i = bytes.count; break }
                let d1 = bytes[i]
                let d2 = bytes[i + 1]
                i += 2
                let evtType: MidiEventType
                var velocity: UInt32? = nil
                var controllerValue: UInt32? = nil
                var note: UInt8? = d1
                switch type {
                case 0x80:
                    evtType = .noteOff
                    velocity = UInt32(d2)
                case 0x90:
                    evtType = d2 == 0 ? .noteOff : .noteOn
                    velocity = UInt32(d2)
                case 0xA0:
                    evtType = .polyphonicKeyPressure
                    velocity = UInt32(d2)
                case 0xB0:
                    evtType = .controlChange
                    controllerValue = UInt32(d2)
                case 0xE0:
                    evtType = .pitchBend
                    let value = UInt32(UInt16(d2) << 7 | UInt16(d1))
                    controllerValue = value
                    note = nil
                default:
                    evtType = .unknown
                }
                let event = ChannelVoiceEvent(timestamp: 0,
                                              type: evtType,
                                              group: group,
                                              channel: channel,
                                              noteNumber: note,
                                              velocity: velocity,
                                              controllerValue: controllerValue)
                events.append(event)
            case 0xC0, 0xD0:
                guard i < bytes.count else { i = bytes.count; break }
                let d1 = bytes[i]
                i += 1
                let evtType: MidiEventType = type == 0xC0 ? .programChange : .channelPressure
                let event = ChannelVoiceEvent(timestamp: 0,
                                              type: evtType,
                                              group: group,
                                              channel: channel,
                                              noteNumber: nil,
                                              velocity: nil,
                                              controllerValue: UInt32(d1))
                events.append(event)
            case 0xF0:
                if status == 0xF0 {
                    // SysEx message
                    var payload: [UInt8] = [0xF0]
                    while i < bytes.count && bytes[i] != 0xF7 {
                        payload.append(bytes[i])
                        i += 1
                    }
                    if i < bytes.count && bytes[i] == 0xF7 {
                        payload.append(0xF7)
                        i += 1
                    }
                    let event = SysExEvent(timestamp: 0, data: Data(payload), group: group)
                    events.append(event)
                } else {
                    // Other system messages are ignored; consume their data bytes
                    let dataLength: Int
                    switch status {
                    case 0xF1, 0xF3: dataLength = 1
                    case 0xF2: dataLength = 2
                    default: dataLength = 0
                    }
                    i += dataLength
                }
                runningStatus = 0
            default:
                // Skip unsupported message (e.g., system common)
                if status >= 0xF0 {
                    // system messages have no running status
                    runningStatus = 0
                }
                // Advance if we didn't consume a data byte earlier
                if bytes[i] >= 0x80 {
                    // already advanced when setting runningStatus
                } else {
                    i += 1
                }
            }
        }
        return UMPEncoder.encodeEvents(events, defaultGroup: group)
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.

