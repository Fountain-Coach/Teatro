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

    /// Basic MIDI event representation used by `parseTrack`.
    enum MidiEvent {
        case noteOn(deltaTime: UInt32, channel: UInt8, note: UInt8, velocity: UInt8)
        case noteOff(deltaTime: UInt32, channel: UInt8, note: UInt8, velocity: UInt8)
        case meta(deltaTime: UInt32, type: UInt8, data: Data)
    }

    /// Parses a track chunk (MTrk) from a MIDI file.
    /// - Parameter data: Data starting at the beginning of the `MTrk` chunk.
    /// - Returns: Array of decoded `MidiEvent` values.
    static func parseTrack(data: Data) throws -> [MidiEvent] {
        guard data.count >= 8 else { throw MidiFileParserError.invalidTrack }
        guard data.prefix(4) == Data([0x4D, 0x54, 0x72, 0x6B]) else { throw MidiFileParserError.invalidTrack }
        let length = UInt32(bigEndian: data[4..<8].withUnsafeBytes { $0.load(as: UInt32.self) })
        var index = 8
        let end = index + Int(length)
        var runningStatus: UInt8?
        var events: [MidiEvent] = []

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
                events.append(.noteOff(deltaTime: delta, channel: channel, note: note, velocity: velocity))
                index += 2
            case 0x90: // Note On
                guard index + 1 < end else { throw MidiFileParserError.invalidEvent }
                let note = data[index]
                let velocity = data[index + 1]
                events.append(.noteOn(deltaTime: delta, channel: channel, note: note, velocity: velocity))
                index += 2
            case 0xA0, 0xB0, 0xE0: // Two data bytes, skip
                index += 2
            case 0xC0, 0xD0: // One data byte, skip
                index += 1
            case 0xF0:
                if status == 0xFF { // Meta event
                    guard index < end else { throw MidiFileParserError.invalidEvent }
                    let metaType = data[index]
                    index += 1
                    let length = try readVariableLengthQuantity(data, index: &index)
                    guard index + Int(length) <= end else { throw MidiFileParserError.invalidEvent }
                    let metaData = data[index..<index + Int(length)]
                    events.append(.meta(deltaTime: delta, type: metaType, data: metaData))
                    index += Int(length)
                    if metaType == 0x2F { break } // End of track
                } else if status == 0xF0 || status == 0xF7 { // SysEx
                    let length = try readVariableLengthQuantity(data, index: &index)
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

© 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
