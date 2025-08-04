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
}

© 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
