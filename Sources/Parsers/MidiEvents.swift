import Foundation

/// High-level MIDI event categories.
enum MidiEventType {
    case noteOn
    case noteOff
    case controlChange
    case programChange
    case pitchBend
    case channelPressure
    case polyphonicKeyPressure
    case meta
    case sysEx
    case unknown
}

/// Protocol describing a normalized MIDI event.
protocol MidiEventProtocol {
    var timestamp: UInt32 { get }
    var type: MidiEventType { get }
    /// MIDI 2.0 group number if present.
    var group: UInt8? { get }
    var channel: UInt8? { get }
    var noteNumber: UInt8? { get }
    var velocity: UInt8? { get }
    var controllerValue: UInt32? { get }
    var metaType: UInt8? { get }
    var rawData: Data? { get }
    static func normalizeVelocity(_ value: UInt16) -> UInt8
    static func normalizeController(_ value: UInt32) -> UInt8
}

extension MidiEventProtocol {
    var group: UInt8? { nil }
    static func normalizeVelocity(_ value: UInt16) -> UInt8 {
        return UInt8(truncatingIfNeeded: value >> 8)
    }

    static func normalizeController(_ value: UInt32) -> UInt8 {
        return UInt8(truncatingIfNeeded: value >> 24)
    }
}

/// Represents channel voice messages such as Note On/Off and Control Change.
struct ChannelVoiceEvent: MidiEventProtocol {
    let timestamp: UInt32
    let type: MidiEventType
    let group: UInt8?
    let channel: UInt8?
    let noteNumber: UInt8?
    let velocity: UInt8?
    let controllerValue: UInt32?
    var metaType: UInt8? { nil }
    var rawData: Data? { nil }
}

/// Represents meta events contained within SMF tracks.
struct MetaEvent: MidiEventProtocol {
    let timestamp: UInt32
    let meta: UInt8
    let data: Data

    var type: MidiEventType { .meta }
    var channel: UInt8? { nil }
    var noteNumber: UInt8? { nil }
    var velocity: UInt8? { nil }
    var controllerValue: UInt32? { nil }
    var metaType: UInt8? { meta }
    var rawData: Data? { data }
}

/// Represents tempo meta events.
struct TempoEvent: MidiEventProtocol {
    let timestamp: UInt32
    /// Microseconds per quarter note.
    let microsecondsPerQuarter: UInt32

    var type: MidiEventType { .meta }
    var channel: UInt8? { nil }
    var noteNumber: UInt8? { nil }
    var velocity: UInt8? { nil }
    var controllerValue: UInt32? { nil }
    var metaType: UInt8? { 0x51 }
    var rawData: Data? {
        let b1 = UInt8((microsecondsPerQuarter >> 16) & 0xFF)
        let b2 = UInt8((microsecondsPerQuarter >> 8) & 0xFF)
        let b3 = UInt8(microsecondsPerQuarter & 0xFF)
        return Data([b1, b2, b3])
    }
}

/// Represents time signature meta events.
struct TimeSignatureEvent: MidiEventProtocol {
    let timestamp: UInt32
    let numerator: UInt8
    /// Denominator expressed as the actual value (e.g. 4 for 4/4).
    let denominator: UInt8
    let metronome: UInt8
    let thirtySeconds: UInt8

    var type: MidiEventType { .meta }
    var channel: UInt8? { nil }
    var noteNumber: UInt8? { nil }
    var velocity: UInt8? { nil }
    var controllerValue: UInt32? { nil }
    var metaType: UInt8? { 0x58 }
    var rawData: Data? {
        var exp: UInt8 = 0
        var denom = denominator
        while denom > 1 {
            denom >>= 1
            exp += 1
        }
        return Data([numerator, exp, metronome, thirtySeconds])
    }
}

/// Represents track name meta events.
struct TrackNameEvent: MidiEventProtocol {
    let timestamp: UInt32
    let name: String

    var type: MidiEventType { .meta }
    var channel: UInt8? { nil }
    var noteNumber: UInt8? { nil }
    var velocity: UInt8? { nil }
    var controllerValue: UInt32? { nil }
    var metaType: UInt8? { 0x03 }
    var rawData: Data? { name.data(using: .utf8) }
}

/// Represents instrument name meta events.
struct InstrumentNameEvent: MidiEventProtocol {
    let timestamp: UInt32
    let name: String

    var type: MidiEventType { .meta }
    var channel: UInt8? { nil }
    var noteNumber: UInt8? { nil }
    var velocity: UInt8? { nil }
    var controllerValue: UInt32? { nil }
    var metaType: UInt8? { 0x04 }
    var rawData: Data? { name.data(using: .utf8) }
}

/// Represents lyric meta events.
struct LyricEvent: MidiEventProtocol {
    let timestamp: UInt32
    let text: String

    var type: MidiEventType { .meta }
    var channel: UInt8? { nil }
    var noteNumber: UInt8? { nil }
    var velocity: UInt8? { nil }
    var controllerValue: UInt32? { nil }
    var metaType: UInt8? { 0x05 }
    var rawData: Data? { text.data(using: .utf8) }
}

/// Represents marker meta events.
struct MarkerEvent: MidiEventProtocol {
    let timestamp: UInt32
    let name: String

    var type: MidiEventType { .meta }
    var channel: UInt8? { nil }
    var noteNumber: UInt8? { nil }
    var velocity: UInt8? { nil }
    var controllerValue: UInt32? { nil }
    var metaType: UInt8? { 0x06 }
    var rawData: Data? { name.data(using: .utf8) }
}

/// Represents cue point meta events.
struct CuePointEvent: MidiEventProtocol {
    let timestamp: UInt32
    let text: String

    var type: MidiEventType { .meta }
    var channel: UInt8? { nil }
    var noteNumber: UInt8? { nil }
    var velocity: UInt8? { nil }
    var controllerValue: UInt32? { nil }
    var metaType: UInt8? { 0x07 }
    var rawData: Data? { text.data(using: .utf8) }
}

/// Represents key signature meta events.
struct KeySignatureEvent: MidiEventProtocol {
    let timestamp: UInt32
    /// Number of sharps (positive) or flats (negative) in the key.
    let key: Int8
    /// `true` if the key is minor; `false` for major.
    let isMinor: Bool

    var type: MidiEventType { .meta }
    var channel: UInt8? { nil }
    var noteNumber: UInt8? { nil }
    var velocity: UInt8? { nil }
    var controllerValue: UInt32? { nil }
    var metaType: UInt8? { 0x59 }
    var rawData: Data? { Data([UInt8(bitPattern: key), isMinor ? 1 : 0]) }
}

/// Represents SMPTE offset meta events.
struct SMPTEOffsetEvent: MidiEventProtocol {
    let timestamp: UInt32
    let hour: UInt8
    let minute: UInt8
    let second: UInt8
    let frame: UInt8
    let subframe: UInt8

    var type: MidiEventType { .meta }
    var channel: UInt8? { nil }
    var noteNumber: UInt8? { nil }
    var velocity: UInt8? { nil }
    var controllerValue: UInt32? { nil }
    var metaType: UInt8? { 0x54 }
    var rawData: Data? { Data([hour, minute, second, frame, subframe]) }
}

/// Represents SysEx events.
struct SysExEvent: MidiEventProtocol {
    let timestamp: UInt32
    let data: Data
    let group: UInt8?

    var type: MidiEventType { .sysEx }
    var channel: UInt8? { nil }
    var noteNumber: UInt8? { nil }
    var velocity: UInt8? { nil }
    var controllerValue: UInt32? { nil }
    var metaType: UInt8? { nil }
    var rawData: Data? { data }
}

/// Represents any event that does not fit into the other categories.
struct UnknownEvent: MidiEventProtocol {
    let timestamp: UInt32
    let data: Data
    let group: UInt8?

    var type: MidiEventType { .unknown }
    var channel: UInt8? { nil }
    var noteNumber: UInt8? { nil }
    var velocity: UInt8? { nil }
    var controllerValue: UInt32? { nil }
    var metaType: UInt8? { nil }
    var rawData: Data? { data }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
