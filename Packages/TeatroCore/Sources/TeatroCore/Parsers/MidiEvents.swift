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
    case perNotePitch
    case rpn
    case nrpn
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
public struct ChannelVoiceEvent: MidiEventProtocol {
    public let timestamp: UInt32
    public let type: MidiEventType
    public let group: UInt8?
    public let channel: UInt8?
    public let noteNumber: UInt8?
    public let velocity: UInt32?
    public let controllerValue: UInt32?
    public var metaType: UInt8? { nil }
    public var rawData: Data? { nil }

    public init(timestamp: UInt32,
                type: MidiEventType,
                group: UInt8?,
                channel: UInt8?,
                noteNumber: UInt8?,
                velocity: UInt32?,
                controllerValue: UInt32?) {
        self.timestamp = timestamp
        self.type = type
        self.group = group
        self.channel = channel
        self.noteNumber = noteNumber
        self.velocity = velocity
        self.controllerValue = controllerValue
    }
}

/// Represents per-note controller messages in MIDI 2.0.
public struct PerNoteControllerEvent: MidiEventProtocol {
    public let timestamp: UInt32
    public let type: MidiEventType = .perNoteController
    public let group: UInt8?
    public let channel: UInt8?
    public let noteNumber: UInt8?
    public let controllerIndex: UInt8
    public let controllerValue: UInt32?
    public var velocity: UInt32? { nil }
    public var metaType: UInt8? { nil }
    public var rawData: Data? { nil }

    public init(timestamp: UInt32,
                group: UInt8?,
                channel: UInt8?,
                noteNumber: UInt8?,
                controllerIndex: UInt8,
                controllerValue: UInt32?) {
        self.timestamp = timestamp
        self.group = group
        self.channel = channel
        self.noteNumber = noteNumber
        self.controllerIndex = controllerIndex
        self.controllerValue = controllerValue
    }
}


/// Represents per-note attribute messages in MIDI 2.0.
public struct NoteAttributeEvent: MidiEventProtocol {
    public let timestamp: UInt32
    public let type: MidiEventType = .noteAttribute
    public let group: UInt8?
    public let channel: UInt8?
    public let noteNumber: UInt8?
    public let attributeIndex: UInt8
    public let attributeValue: UInt32
    public var velocity: UInt32? { nil }
    public var controllerValue: UInt32? { attributeValue }
    public var metaType: UInt8? { nil }
    public var rawData: Data? { nil }

    public init(timestamp: UInt32,
                group: UInt8?,
                channel: UInt8?,
                noteNumber: UInt8?,
                attributeIndex: UInt8,
                attributeValue: UInt32) {
        self.timestamp = timestamp
        self.group = group
        self.channel = channel
        self.noteNumber = noteNumber
        self.attributeIndex = attributeIndex
        self.attributeValue = attributeValue
    }
}

/// Defined attribute types for extended note messages.
public enum NoteAttributeType: UInt8 {
    case none = 0x00
    case manufacturerSpecific = 0x01
    case profileSpecific = 0x02
    case pitch7_9 = 0x03
    case unknown = 0xFF

    public init(rawValue: UInt8) {
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
public struct NoteOnWithAttributeEvent: MidiEventProtocol {
    public let timestamp: UInt32
    public let group: UInt8?
    public let channel: UInt8?
    public let noteNumber: UInt8?
    public let velocity: UInt32?
    public let attributeType: NoteAttributeType
    public let attributeData: UInt16

    public var type: MidiEventType { attributeType == .unknown ? .unknown : .noteOnWithAttribute }
    public var controllerValue: UInt32? { nil }
    public var metaType: UInt8? { nil }
    public var rawData: Data? { nil }

    public init(timestamp: UInt32,
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
public struct NoteOffWithAttributeEvent: MidiEventProtocol {
    public let timestamp: UInt32
    public let group: UInt8?
    public let channel: UInt8?
    public let noteNumber: UInt8?
    public let velocity: UInt32?
    public let attributeType: NoteAttributeType
    public let attributeData: UInt16

    public var type: MidiEventType { attributeType == .unknown ? .unknown : .noteOffWithAttribute }
    public var controllerValue: UInt32? { nil }
    public var metaType: UInt8? { nil }
    public var rawData: Data? { nil }

    public init(timestamp: UInt32,
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
public struct NoteEndEvent: MidiEventProtocol {
    public let timestamp: UInt32
    public let group: UInt8?
    public let channel: UInt8?
    public let noteNumber: UInt8?
    public let velocity: UInt32?
    public let attributeType: NoteAttributeType
    public let attributeData: UInt16

    public var type: MidiEventType { attributeType == .unknown ? .unknown : .noteEnd }
    public var controllerValue: UInt32? { nil }
    public var metaType: UInt8? { nil }
    public var rawData: Data? { nil }

    public init(timestamp: UInt32,
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
public struct PitchClampEvent: MidiEventProtocol {
    public let timestamp: UInt32
    public let group: UInt8?
    public let channel: UInt8?
    public let noteNumber: UInt8?
    public let pitch: UInt32

    public var type: MidiEventType { .pitchClamp }
    public var velocity: UInt32? { nil }
    public var controllerValue: UInt32? { pitch }
    public var metaType: UInt8? { nil }
    public var rawData: Data? { nil }

    public init(timestamp: UInt32,
                group: UInt8?,
                channel: UInt8?,
                noteNumber: UInt8?,
                pitch: UInt32) {
        self.timestamp = timestamp
        self.group = group
        self.channel = channel
        self.noteNumber = noteNumber
        self.pitch = pitch
    }
}

/// Represents a Pitch Release message.
public struct PitchReleaseEvent: MidiEventProtocol {
    public let timestamp: UInt32
    public let group: UInt8?
    public let channel: UInt8?
    public let noteNumber: UInt8?

    public var type: MidiEventType { .pitchRelease }
    public var velocity: UInt32? { nil }
    public var controllerValue: UInt32? { nil }
    public var metaType: UInt8? { nil }
    public var rawData: Data? { nil }

    public init(timestamp: UInt32,
                group: UInt8?,
                channel: UInt8?,
                noteNumber: UInt8?) {
        self.timestamp = timestamp
        self.group = group
        self.channel = channel
        self.noteNumber = noteNumber
    }
}

/// Represents JR Timestamp utility messages.
public struct JRTimestampEvent: MidiEventProtocol {
    public let timestamp: UInt32
    public let group: UInt8?
    public let value: UInt32

    public var type: MidiEventType { .jrTimestamp }
    public var channel: UInt8? { nil }
    public var noteNumber: UInt8? { nil }
    public var velocity: UInt32? { nil }
    public var controllerValue: UInt32? { value }
    public var metaType: UInt8? { nil }
    public var rawData: Data? { nil }

    public init(timestamp: UInt32, group: UInt8?, value: UInt32) {
        self.timestamp = timestamp
        self.group = group
        self.value = value
    }
}

/// Represents meta events contained within SMF tracks.
public struct MetaEvent: MidiEventProtocol {
    public let timestamp: UInt32
    public let meta: UInt8
    public let data: Data

    public var type: MidiEventType { .meta }
    public var channel: UInt8? { nil }
    public var noteNumber: UInt8? { nil }
    public var velocity: UInt32? { nil }
    public var controllerValue: UInt32? { nil }
    public var metaType: UInt8? { meta }
    public var rawData: Data? { data }
    public init(timestamp: UInt32, meta: UInt8, data: Data) {
        self.timestamp = timestamp
        self.meta = meta
        self.data = data
    }
}

/// Represents tempo meta events.
public struct TempoEvent: MidiEventProtocol {
    public let timestamp: UInt32
    /// Microseconds per quarter note.
    public let microsecondsPerQuarter: UInt32

    public var type: MidiEventType { .meta }
    public var channel: UInt8? { nil }
    public var noteNumber: UInt8? { nil }
    public var velocity: UInt32? { nil }
    public var controllerValue: UInt32? { nil }
    public var metaType: UInt8? { 0x51 }
    public var rawData: Data? {
        let b1 = UInt8((microsecondsPerQuarter >> 16) & 0xFF)
        let b2 = UInt8((microsecondsPerQuarter >> 8) & 0xFF)
        let b3 = UInt8(microsecondsPerQuarter & 0xFF)
        return Data([b1, b2, b3])
    }

    public init(timestamp: UInt32, microsecondsPerQuarter: UInt32) {
        self.timestamp = timestamp
        self.microsecondsPerQuarter = microsecondsPerQuarter
    }
}

/// Represents time signature meta events.
public struct TimeSignatureEvent: MidiEventProtocol {
    public let timestamp: UInt32
    public let numerator: UInt8
    /// Denominator expressed as the actual value (e.g. 4 for 4/4).
    public let denominator: UInt8
    public let metronome: UInt8
    public let thirtySeconds: UInt8

    public var type: MidiEventType { .meta }
    public var channel: UInt8? { nil }
    public var noteNumber: UInt8? { nil }
    public var velocity: UInt32? { nil }
    public var controllerValue: UInt32? { nil }
    public var metaType: UInt8? { 0x58 }
    public var rawData: Data? {
        var exp: UInt8 = 0
        var denom = denominator
        while denom > 1 {
            denom >>= 1
            exp += 1
        }
        return Data([numerator, exp, metronome, thirtySeconds])
    }

    public init(timestamp: UInt32,
                numerator: UInt8,
                denominator: UInt8,
                metronome: UInt8,
                thirtySeconds: UInt8) {
        self.timestamp = timestamp
        self.numerator = numerator
        self.denominator = denominator
        self.metronome = metronome
        self.thirtySeconds = thirtySeconds
    }
}

/// Represents track name meta events.
public struct TrackNameEvent: MidiEventProtocol {
    public let timestamp: UInt32
    public let name: String

    public var type: MidiEventType { .meta }
    public var channel: UInt8? { nil }
    public var noteNumber: UInt8? { nil }
    public var velocity: UInt32? { nil }
    public var controllerValue: UInt32? { nil }
    public var metaType: UInt8? { 0x03 }
    public var rawData: Data? { name.data(using: .utf8) }

    public init(timestamp: UInt32, name: String) {
        self.timestamp = timestamp
        self.name = name
    }
}

/// Represents instrument name meta events.
public struct InstrumentNameEvent: MidiEventProtocol {
    public let timestamp: UInt32
    public let name: String

    public var type: MidiEventType { .meta }
    public var channel: UInt8? { nil }
    public var noteNumber: UInt8? { nil }
    public var velocity: UInt32? { nil }
    public var controllerValue: UInt32? { nil }
    public var metaType: UInt8? { 0x04 }
    public var rawData: Data? { name.data(using: .utf8) }

    public init(timestamp: UInt32, name: String) {
        self.timestamp = timestamp
        self.name = name
    }
}

/// Represents lyric meta events.
public struct LyricEvent: MidiEventProtocol {
    public let timestamp: UInt32
    public let text: String

    public var type: MidiEventType { .meta }
    public var channel: UInt8? { nil }
    public var noteNumber: UInt8? { nil }
    public var velocity: UInt32? { nil }
    public var controllerValue: UInt32? { nil }
    public var metaType: UInt8? { 0x05 }
    public var rawData: Data? { text.data(using: .utf8) }

    public init(timestamp: UInt32, text: String) {
        self.timestamp = timestamp
        self.text = text
    }
}

/// Represents marker meta events.
public struct MarkerEvent: MidiEventProtocol {
    public let timestamp: UInt32
    public let name: String

    public var type: MidiEventType { .meta }
    public var channel: UInt8? { nil }
    public var noteNumber: UInt8? { nil }
    public var velocity: UInt32? { nil }
    public var controllerValue: UInt32? { nil }
    public var metaType: UInt8? { 0x06 }
    public var rawData: Data? { name.data(using: .utf8) }

    public init(timestamp: UInt32, name: String) {
        self.timestamp = timestamp
        self.name = name
    }
}

/// Represents cue point meta events.
public struct CuePointEvent: MidiEventProtocol {
    public let timestamp: UInt32
    public let text: String

    public var type: MidiEventType { .meta }
    public var channel: UInt8? { nil }
    public var noteNumber: UInt8? { nil }
    public var velocity: UInt32? { nil }
    public var controllerValue: UInt32? { nil }
    public var metaType: UInt8? { 0x07 }
    public var rawData: Data? { text.data(using: .utf8) }

    public init(timestamp: UInt32, text: String) {
        self.timestamp = timestamp
        self.text = text
    }
}

/// Represents key signature meta events.
public struct KeySignatureEvent: MidiEventProtocol {
    public let timestamp: UInt32
    /// Number of sharps (positive) or flats (negative) in the key.
    public let key: Int8
    /// `true` if the key is minor; `false` for major.
    public let isMinor: Bool

    public var type: MidiEventType { .meta }
    public var channel: UInt8? { nil }
    public var noteNumber: UInt8? { nil }
    public var velocity: UInt32? { nil }
    public var controllerValue: UInt32? { nil }
    public var metaType: UInt8? { 0x59 }
    public var rawData: Data? { Data([UInt8(bitPattern: key), isMinor ? 1 : 0]) }

    public init(timestamp: UInt32, key: Int8, isMinor: Bool) {
        self.timestamp = timestamp
        self.key = key
        self.isMinor = isMinor
    }
}

/// Represents SMPTE offset meta events.
public struct SMPTEOffsetEvent: MidiEventProtocol {
    public let timestamp: UInt32
    public let hour: UInt8
    public let minute: UInt8
    public let second: UInt8
    public let frame: UInt8
    public let subframe: UInt8

    public var type: MidiEventType { .meta }
    public var channel: UInt8? { nil }
    public var noteNumber: UInt8? { nil }
    public var velocity: UInt32? { nil }
    public var controllerValue: UInt32? { nil }
    public var metaType: UInt8? { 0x54 }
    public var rawData: Data? { Data([hour, minute, second, frame, subframe]) }

    public init(timestamp: UInt32, hour: UInt8, minute: UInt8, second: UInt8, frame: UInt8, subframe: UInt8) {
        self.timestamp = timestamp
        self.hour = hour
        self.minute = minute
        self.second = second
        self.frame = frame
        self.subframe = subframe
    }
}

/// Represents SysEx events.
public struct SysExEvent: MidiEventProtocol {
    public let timestamp: UInt32
    public let data: Data
    public let group: UInt8?

    public var type: MidiEventType { .sysEx }
    public var channel: UInt8? { nil }
    public var noteNumber: UInt8? { nil }
    public var velocity: UInt32? { nil }
    public var controllerValue: UInt32? { nil }
    public var metaType: UInt8? { nil }
    public var rawData: Data? { data }
    public init(timestamp: UInt32, data: Data, group: UInt8?) {
        self.timestamp = timestamp
        self.data = data
        self.group = group
    }
}

/// Represents any event that does not fit into the other categories.
public struct UnknownEvent: MidiEventProtocol {
    public let timestamp: UInt32
    public let data: Data
    public let group: UInt8?

    public var type: MidiEventType { .unknown }
    public var channel: UInt8? { nil }
    public var noteNumber: UInt8? { nil }
    public var velocity: UInt32? { nil }
    public var controllerValue: UInt32? { nil }
    public var metaType: UInt8? { nil }
    public var rawData: Data? { data }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
