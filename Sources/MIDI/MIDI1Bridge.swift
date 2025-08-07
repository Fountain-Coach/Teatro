import Foundation

/// Bridges between Universal MIDI Packets and MIDI 1.0 byte streams.
/// Only channel voice and basic SysEx7 messages are translated. Other
/// packet types are silently ignored so that unsupported data does not
/// terminate the conversion.
public enum MIDI1Bridge {
    /// Converts a stream of UMP data into a MIDI 1.0 byte sequence.
    /// - Parameter data: Raw UMP word bytes (big-endian).
    /// - Returns: MIDI 1.0 bytes. Unsupported messages are discarded.
    public static func umpToMIDI1(_ data: Data) throws -> Data {
        let events = try UMPParser.parse(data: data)
        var bytes: [UInt8] = []
        for event in events {
            guard let ch = event.channel else {
                // SysEx messages have no channel and are handled separately
                if event.type == .sysEx, let raw = event.rawData {
                    // Raw UMP SysEx7 packets start with mt/group byte.
                    // Drop that byte and any trailing padding zeros.
                    var payload = Array(raw.dropFirst())
                    while payload.last == 0 { payload.removeLast() }
                    bytes.append(0xF0)
                    bytes.append(contentsOf: payload)
                    bytes.append(0xF7)
                }
                continue
            }
            switch event.type {
            case .noteOn:
                if let note = event.noteNumber, let vel = event.velocity {
                    bytes.append(0x90 | ch)
                    bytes.append(note)
                    bytes.append(MIDI.midi1Velocity(from: vel))
                }
            case .noteOff:
                if let note = event.noteNumber, let vel = event.velocity {
                    bytes.append(0x80 | ch)
                    bytes.append(note)
                    bytes.append(MIDI.midi1Velocity(from: vel))
                }
            case .polyphonicKeyPressure:
                if let note = event.noteNumber, let vel = event.velocity {
                    bytes.append(0xA0 | ch)
                    bytes.append(note)
                    bytes.append(MIDI.midi1Velocity(from: vel))
                }
            case .controlChange:
                if let controller = event.noteNumber, let val = event.controllerValue {
                    bytes.append(0xB0 | ch)
                    bytes.append(controller)
                    bytes.append(MIDI.midi1Controller(from: val))
                }
            case .programChange:
                if let program = event.controllerValue {
                    bytes.append(0xC0 | ch)
                    bytes.append(UInt8(truncatingIfNeeded: program))
                }
            case .channelPressure:
                if let pressure = event.controllerValue {
                    bytes.append(0xD0 | ch)
                    bytes.append(MIDI.midi1Controller(from: pressure))
                }
            case .pitchBend:
                if let value = event.controllerValue {
                    let bend = MIDI.midi1PitchBend(from: value)
                    bytes.append(0xE0 | ch)
                    bytes.append(UInt8(truncatingIfNeeded: bend & 0x7F))
                    bytes.append(UInt8(truncatingIfNeeded: bend >> 7))
                }
            case .sysEx:
                // SysEx handled above when channel is nil
                continue
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
                    var payload: [UInt8] = []
                    while i < bytes.count && bytes[i] != 0xF7 {
                        payload.append(bytes[i])
                        i += 1
                    }
                    if i < bytes.count && bytes[i] == 0xF7 { i += 1 }
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

