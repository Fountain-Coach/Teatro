import Foundation

/// High-level MIDI event categories.
public enum MidiEventType {
    case noteOn
    case noteOff
    case controlChange
    case programChange
    case pitchBend
    case channelPressure
    case polyphonicKeyPressure
    case perNoteController
    case noteAttribute
    case noteOnWithAttribute
    case noteOffWithAttribute
    case noteEnd
    case pitchClamp
    case pitchRelease
    case jrTimestamp
    case meta
    case sysEx
    case unknown
}

/// Protocol describing a normalized MIDI event.
public protocol MidiEventProtocol {
    var timestamp: UInt32 { get }
    var type: MidiEventType { get }
    /// MIDI 2.0 group number if present.
    var group: UInt8? { get }
    var channel: UInt8? { get }
    var noteNumber: UInt8? { get }
    var velocity: UInt32? { get }
    var controllerValue: UInt32? { get }
    var metaType: UInt8? { get }
    var rawData: Data? { get }
}

public extension MidiEventProtocol {
    var group: UInt8? { nil }
}

/// Represents channel voice messages such as Note On/Off and Control Change.
struct ChannelVoiceEvent: MidiEventProtocol {
    let timestamp: UInt32
    let type: MidiEventType
    let group: UInt8?
    let channel: UInt8?
    let noteNumber: UInt8?
    let velocity: UInt32?
    let controllerValue: UInt32?
    var metaType: UInt8? { nil }
    var rawData: Data? { nil }
}

/// Represents per-note controller messages in MIDI 2.0.
struct PerNoteControllerEvent: MidiEventProtocol {
    let timestamp: UInt32
    let type: MidiEventType = .perNoteController
    let group: UInt8?
    let channel: UInt8?
    let noteNumber: UInt8?
    let controllerIndex: UInt8
    let controllerValue: UInt32?
    var velocity: UInt32? { nil }
    var metaType: UInt8? { nil }
    var rawData: Data? { nil }
}

/// Represents per-note attribute messages in MIDI 2.0.
struct NoteAttributeEvent: MidiEventProtocol {
    let timestamp: UInt32
    let type: MidiEventType = .noteAttribute
    let group: UInt8?
    let channel: UInt8?
    let noteNumber: UInt8?
    let attributeIndex: UInt8
    let attributeValue: UInt32
    var velocity: UInt32? { nil }
    var controllerValue: UInt32? { attributeValue }
    var metaType: UInt8? { nil }
    var rawData: Data? { nil }
}

/// Defined attribute types for extended note messages.
enum NoteAttributeType: UInt8 {
    case none = 0x00
    case manufacturerSpecific = 0x01
    case profileSpecific = 0x02
    case pitch7_9 = 0x03
    case unknown = 0xFF

    init(rawValue: UInt8) {
        switch rawValue {
        case 0x00: self = .none
        case 0x01: self = .manufacturerSpecific
        case 0x02: self = .profileSpecific
        case 0x03: self = .pitch7_9
        default: self = .unknown
        }
    }
}

/// Represents MIDI 2.0 Note On message carrying attribute data.
struct NoteOnWithAttributeEvent: MidiEventProtocol {
    let timestamp: UInt32
    let group: UInt8?
    let channel: UInt8?
    let noteNumber: UInt8?
    let velocity: UInt32?
    let attributeType: NoteAttributeType
    let attributeData: UInt16

    var type: MidiEventType { attributeType == .unknown ? .unknown : .noteOnWithAttribute }
    var controllerValue: UInt32? { nil }
    var metaType: UInt8? { nil }
    var rawData: Data? { nil }

    init(timestamp: UInt32,
         group: UInt8?,
         channel: UInt8?,
         noteNumber: UInt8?,
         velocity: UInt32,
         attributeType: UInt8,
         attributeData: UInt16) {
        self.timestamp = timestamp
        self.group = group
        self.channel = channel
        self.noteNumber = noteNumber
        self.velocity = velocity
        self.attributeType = NoteAttributeType(rawValue: attributeType)
        self.attributeData = attributeData
    }
}

/// Represents MIDI 2.0 Note Off message carrying attribute data.
struct NoteOffWithAttributeEvent: MidiEventProtocol {
    let timestamp: UInt32
    let group: UInt8?
    let channel: UInt8?
    let noteNumber: UInt8?
    let velocity: UInt32?
    let attributeType: NoteAttributeType
    let attributeData: UInt16

    var type: MidiEventType { attributeType == .unknown ? .unknown : .noteOffWithAttribute }
    var controllerValue: UInt32? { nil }
    var metaType: UInt8? { nil }
    var rawData: Data? { nil }

    init(timestamp: UInt32,
         group: UInt8?,
         channel: UInt8?,
         noteNumber: UInt8?,
         velocity: UInt32,
         attributeType: UInt8,
         attributeData: UInt16) {
        self.timestamp = timestamp
        self.group = group
        self.channel = channel
        self.noteNumber = noteNumber
        self.velocity = velocity
        self.attributeType = NoteAttributeType(rawValue: attributeType)
        self.attributeData = attributeData
    }
}

/// Represents a Note End message.
struct NoteEndEvent: MidiEventProtocol {
    let timestamp: UInt32
    let group: UInt8?
    let channel: UInt8?
    let noteNumber: UInt8?
    let velocity: UInt32?
    let attributeType: NoteAttributeType
    let attributeData: UInt16

    var type: MidiEventType { attributeType == .unknown ? .unknown : .noteEnd }
    var controllerValue: UInt32? { nil }
    var metaType: UInt8? { nil }
    var rawData: Data? { nil }

    init(timestamp: UInt32,
         group: UInt8?,
         channel: UInt8?,
         noteNumber: UInt8?,
         velocity: UInt32,
         attributeType: UInt8,
         attributeData: UInt16) {
        self.timestamp = timestamp
        self.group = group
        self.channel = channel
        self.noteNumber = noteNumber
        self.velocity = velocity
        self.attributeType = NoteAttributeType(rawValue: attributeType)
        self.attributeData = attributeData
    }
}

/// Represents a Pitch Clamp message.
struct PitchClampEvent: MidiEventProtocol {
    let timestamp: UInt32
    let group: UInt8?
    let channel: UInt8?
    let noteNumber: UInt8?
    let pitch: UInt32

    var type: MidiEventType { .pitchClamp }
    var velocity: UInt32? { nil }
    var controllerValue: UInt32? { pitch }
    var metaType: UInt8? { nil }
    var rawData: Data? { nil }
}

/// Represents a Pitch Release message.
struct PitchReleaseEvent: MidiEventProtocol {
    let timestamp: UInt32
    let group: UInt8?
    let channel: UInt8?
    let noteNumber: UInt8?

    var type: MidiEventType { .pitchRelease }
    var velocity: UInt32? { nil }
    var controllerValue: UInt32? { nil }
    var metaType: UInt8? { nil }
    var rawData: Data? { nil }
}

/// Represents JR Timestamp utility messages.
struct JRTimestampEvent: MidiEventProtocol {
    let timestamp: UInt32
    let group: UInt8?
    let value: UInt32

    var type: MidiEventType { .jrTimestamp }
    var channel: UInt8? { nil }
    var noteNumber: UInt8? { nil }
    var velocity: UInt32? { nil }
    var controllerValue: UInt32? { value }
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
    var velocity: UInt32? { nil }
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
    var velocity: UInt32? { nil }
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
    var velocity: UInt32? { nil }
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
    var velocity: UInt32? { nil }
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
    var velocity: UInt32? { nil }
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
    var velocity: UInt32? { nil }
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
    var velocity: UInt32? { nil }
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
    var velocity: UInt32? { nil }
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
    var velocity: UInt32? { nil }
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
    var velocity: UInt32? { nil }
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
    var velocity: UInt32? { nil }
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
    var velocity: UInt32? { nil }
    var controllerValue: UInt32? { nil }
    var metaType: UInt8? { nil }
    var rawData: Data? { data }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
