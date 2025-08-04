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
        var runningStatus: UInt8?
        var events: [any MidiEventProtocol] = []

        while index < end {
            let delta = try readVariableLengthQuantity(data, index: &index)
            guard index < end else { throw MidiFileParserError.invalidEvent }
            var status = data[index]
            if status < 0x80 {
                guard let rs = runningStatus else { throw MidiFileParserError.invalidEvent }
                status = rs
            } else {
                runningStatus = status
                index += 1
            }

            let type = status & 0xF0
            let channel = status & 0x0F
            switch type {
            case 0x80: // Note Off
                guard index + 1 < end else { throw MidiFileParserError.invalidEvent }
                let note = data[index]
                let velocity = data[index + 1]
                events.append(ChannelVoiceEvent(timestamp: delta, type: .noteOff, channelNumber: channel, noteNumber: note, velocity: velocity, controllerValue: nil))
                index += 2
            case 0x90: // Note On
                guard index + 1 < end else { throw MidiFileParserError.invalidEvent }
                let note = data[index]
                let velocity = data[index + 1]
                events.append(ChannelVoiceEvent(timestamp: delta, type: .noteOn, channelNumber: channel, noteNumber: note, velocity: velocity, controllerValue: nil))
                index += 2
            case 0xB0: // Control Change
                guard index + 1 < end else { throw MidiFileParserError.invalidEvent }
                let controller = data[index]
                let value = data[index + 1]
                events.append(ChannelVoiceEvent(timestamp: delta, type: .controlChange, channelNumber: channel, noteNumber: controller, velocity: nil, controllerValue: UInt32(value)))
                index += 2
            case 0xC0: // Program Change
                guard index < end else { throw MidiFileParserError.invalidEvent }
                let program = data[index]
                events.append(ChannelVoiceEvent(timestamp: delta, type: .programChange, channelNumber: channel, noteNumber: nil, velocity: nil, controllerValue: UInt32(program)))
                index += 1
            case 0xE0: // Pitch Bend
                guard index + 1 < end else { throw MidiFileParserError.invalidEvent }
                let lsb = UInt16(data[index])
                let msb = UInt16(data[index + 1])
                let value = (msb << 7) | lsb
                events.append(ChannelVoiceEvent(timestamp: delta, type: .pitchBend, channelNumber: channel, noteNumber: nil, velocity: nil, controllerValue: UInt32(value)))
                index += 2
            case 0xA0: // Polyphonic Key Pressure - ignore contents
                index += 2
            case 0xD0: // Channel Pressure
                guard index < end else { throw MidiFileParserError.invalidEvent }
                let pressure = data[index]
                events.append(ChannelVoiceEvent(timestamp: delta, type: .channelPressure, channelNumber: channel, noteNumber: nil, velocity: nil, controllerValue: UInt32(pressure)))
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

                    let payload = Data(metaSlice)
                    events.append(MetaEvent(timestamp: delta, meta: metaType, data: payload))
                    if metaType == 0x2F { break } // End of track
                } else if status == 0xF0 || status == 0xF7 { // SysEx
                    let length = try readVariableLengthQuantity(data, index: &index)
                    guard index + Int(length) <= end else { throw MidiFileParserError.invalidEvent }
                    let sysExData = data[index..<index + Int(length)]
                    events.append(SysExEvent(timestamp: delta, data: Data(sysExData)))
                    index += Int(length)
                } else {
                    // Other system messages ignored
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
