import Foundation

/// Represents the header of a Standard MIDI File.
struct MidiFileHeader {
    let format: UInt16
    let trackCount: UInt16
    let division: UInt16
}

/// Errors that can occur while parsing a Standard MIDI File.
enum MidiFileParserError: Error {
    case invalidHeader
    case invalidTrack
    case invalidEvent
}

/// Parser for Standard MIDI Files (SMF).
struct MidiFileParser {
    /// Parses the header chunk (MThd) of a MIDI file.
    /// - Parameter data: The raw data of the MIDI file beginning at the header.
    /// - Returns: A `MidiFileHeader` describing the file.
    static func parseHeader(data: Data) throws -> MidiFileHeader {
        guard data.count >= 14 else { throw MidiFileParserError.invalidHeader }
        let magic = data.prefix(4)
        guard magic == Data([0x4D, 0x54, 0x68, 0x64]) else { throw MidiFileParserError.invalidHeader }
        let length = UInt32(bigEndian: data[4..<8].withUnsafeBytes { $0.load(as: UInt32.self) })
        guard length == 6 else { throw MidiFileParserError.invalidHeader }
        let format = UInt16(bigEndian: data[8..<10].withUnsafeBytes { $0.load(as: UInt16.self) })
        let trackCount = UInt16(bigEndian: data[10..<12].withUnsafeBytes { $0.load(as: UInt16.self) })
        let division = UInt16(bigEndian: data[12..<14].withUnsafeBytes { $0.load(as: UInt16.self) })
        return MidiFileHeader(format: format, trackCount: trackCount, division: division)
    }

    /// Parses a track chunk (MTrk) from a MIDI file.
    /// - Parameter data: Data starting at the beginning of the `MTrk` chunk.
    /// - Returns: Array of decoded `MidiEventProtocol` values.
    static func parseTrack(data: Data) throws -> [any MidiEventProtocol] {
        guard data.count >= 8 else { throw MidiFileParserError.invalidTrack }
        guard data.prefix(4) == Data([0x4D, 0x54, 0x72, 0x6B]) else { throw MidiFileParserError.invalidTrack }
        let length = UInt32(bigEndian: data[4..<8].withUnsafeBytes { $0.load(as: UInt32.self) })
        var index = 8
        let end = index + Int(length)
        guard end <= data.count else { throw MidiFileParserError.invalidTrack }
        var runningStatus: UInt8?
        var events: [any MidiEventProtocol] = []
        var currentTime: UInt32 = 0

        while index < end {
            let delta = try readVariableLengthQuantity(data, index: &index)
            currentTime += delta
            guard index < end else { throw MidiFileParserError.invalidEvent }
            var status = data[index]
            if status < 0x80 {
                guard let rs = runningStatus else { throw MidiFileParserError.invalidEvent }
                status = rs
            } else {
                index += 1
                if status < 0xF0 {
                    runningStatus = status
                } else if status < 0xF8 {
                    runningStatus = nil
                }
            }

            let type = status & 0xF0
            let channel = status & 0x0F
            switch type {
            case 0x80: // Note Off
                guard index + 1 < end else { throw MidiFileParserError.invalidEvent }
                let note = data[index]
                let velocity = data[index + 1]
                events.append(ChannelVoiceEvent(timestamp: currentTime, type: .noteOff, channelNumber: channel, noteNumber: note, velocity: velocity, controllerValue: nil))
                index += 2
            case 0x90: // Note On (velocity 0 treated as Note Off)
                guard index + 1 < end else { throw MidiFileParserError.invalidEvent }
                let note = data[index]
                let velocity = data[index + 1]
                let eventType: MidiEventType = velocity == 0 ? .noteOff : .noteOn
                events.append(ChannelVoiceEvent(timestamp: currentTime, type: eventType, channelNumber: channel, noteNumber: note, velocity: velocity, controllerValue: nil))
                index += 2
            case 0xB0: // Control Change
                guard index + 1 < end else { throw MidiFileParserError.invalidEvent }
                let controller = data[index]
                let value = data[index + 1]
                events.append(ChannelVoiceEvent(timestamp: currentTime, type: .controlChange, channelNumber: channel, noteNumber: controller, velocity: nil, controllerValue: UInt32(value)))
                index += 2
            case 0xC0: // Program Change
                guard index < end else { throw MidiFileParserError.invalidEvent }
                let program = data[index]
                events.append(ChannelVoiceEvent(timestamp: currentTime, type: .programChange, channelNumber: channel, noteNumber: nil, velocity: nil, controllerValue: UInt32(program)))
                index += 1
            case 0xE0: // Pitch Bend
                guard index + 1 < end else { throw MidiFileParserError.invalidEvent }
                let lsb = UInt16(data[index])
                let msb = UInt16(data[index + 1])
                let value = (msb << 7) | lsb
                events.append(ChannelVoiceEvent(timestamp: currentTime, type: .pitchBend, channelNumber: channel, noteNumber: nil, velocity: nil, controllerValue: UInt32(value)))
                index += 2
            case 0xA0: // Polyphonic Key Pressure
                guard index + 1 < end else { throw MidiFileParserError.invalidEvent }
                let note = data[index]
                let pressure = data[index + 1]
                events.append(ChannelVoiceEvent(timestamp: currentTime, type: .polyphonicKeyPressure, channelNumber: channel, noteNumber: note, velocity: pressure, controllerValue: nil))
                index += 2
            case 0xD0: // Channel Pressure
                guard index < end else { throw MidiFileParserError.invalidEvent }
                let pressure = data[index]
                events.append(ChannelVoiceEvent(timestamp: currentTime, type: .channelPressure, channelNumber: channel, noteNumber: nil, velocity: nil, controllerValue: UInt32(pressure)))
                index += 1
            case 0xF0:
                if status == 0xFF { // Meta event
                    guard index < end else { throw MidiFileParserError.invalidEvent }
                    let metaType = data[index]
                    index += 1
                    let length = try readVariableLengthQuantity(data, index: &index)
                    guard index + Int(length) <= end else { throw MidiFileParserError.invalidEvent }
                    let metaSlice = data[index..<index + Int(length)]
                    defer { index += Int(length) }

                    if metaType == 0x03 {
                        let name = String(data: metaSlice, encoding: .utf8) ?? ""
                        events.append(TrackNameEvent(timestamp: currentTime, name: name))
                    } else if metaType == 0x04 {
                        let name = String(data: metaSlice, encoding: .utf8) ?? ""
                        events.append(InstrumentNameEvent(timestamp: currentTime, name: name))
                    } else if metaType == 0x05 {
                        let text = String(data: metaSlice, encoding: .utf8) ?? ""
                        events.append(LyricEvent(timestamp: currentTime, text: text))
                    } else if metaType == 0x06 {
                        let name = String(data: metaSlice, encoding: .utf8) ?? ""
                        events.append(MarkerEvent(timestamp: currentTime, name: name))
                    } else if metaType == 0x07 {
                        let text = String(data: metaSlice, encoding: .utf8) ?? ""
                        events.append(CuePointEvent(timestamp: currentTime, text: text))
                    } else if metaType == 0x51 && length == 3 {
                        var value: UInt32 = 0
                        let start = metaSlice.startIndex
                        value |= UInt32(metaSlice[start]) << 16
                        value |= UInt32(metaSlice[start.advanced(by: 1)]) << 8
                        value |= UInt32(metaSlice[start.advanced(by: 2)])
                        events.append(TempoEvent(timestamp: currentTime, microsecondsPerQuarter: value))
                    } else if metaType == 0x58 && length == 4 {
                        let start = metaSlice.startIndex
                        let numerator = metaSlice[start]
                        let denomExp = metaSlice[start.advanced(by: 1)]
                        let denominator = UInt8(1 << denomExp)
                        let metronome = metaSlice[start.advanced(by: 2)]
                        let thirtySeconds = metaSlice[start.advanced(by: 3)]
                        events.append(TimeSignatureEvent(timestamp: currentTime, numerator: numerator, denominator: denominator, metronome: metronome, thirtySeconds: thirtySeconds))
                    } else if metaType == 0x59 && length >= 2 {
                        let key = Int8(bitPattern: metaSlice[metaSlice.startIndex])
                        let isMinor = metaSlice[metaSlice.startIndex.advanced(by: 1)] == 1
                        events.append(KeySignatureEvent(timestamp: currentTime, key: key, isMinor: isMinor))
                    } else {
                        let payload = Data(metaSlice)
                        events.append(MetaEvent(timestamp: currentTime, meta: metaType, data: payload))
                    }
                    if metaType == 0x2F { break } // End of track
                } else if status == 0xF0 || status == 0xF7 { // SysEx
                    let length = try readVariableLengthQuantity(data, index: &index)
                    guard index + Int(length) <= end else { throw MidiFileParserError.invalidEvent }
                    let sysExData = data[index..<index + Int(length)]
                    events.append(SysExEvent(timestamp: currentTime, data: Data(sysExData)))
                    index += Int(length)
                } else {
                    let length: Int
                    switch status {
                    case 0xF1, 0xF3:
                        length = 1
                    case 0xF2:
                        length = 2
                    case 0xF6, 0xF8, 0xFA, 0xFB, 0xFC, 0xFE:
                        length = 0
                    default:
                        length = 0
                    }
                    guard index + length <= end else { throw MidiFileParserError.invalidEvent }
                    var raw: [UInt8] = [status]
                    for i in 0..<length {
                        raw.append(data[index + i])
                    }
                    events.append(UnknownEvent(timestamp: currentTime, data: Data(raw)))
                    index += length
                }
            default:
                throw MidiFileParserError.invalidEvent
            }
        }

        return events
    }

    /// Reads a variable-length quantity starting at `index` and advances the index.
    private static func readVariableLengthQuantity(_ data: Data, index: inout Int) throws -> UInt32 {
        var value: UInt32 = 0
        while true {
            guard index < data.count else { throw MidiFileParserError.invalidEvent }
            let byte = data[index]
            index += 1
            value = (value << 7) | UInt32(byte & 0x7F)
            if byte & 0x80 == 0 { break }
        }
        return value
    }
}
// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
