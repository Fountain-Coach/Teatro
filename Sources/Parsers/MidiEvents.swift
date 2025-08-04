import Foundation

/// High-level MIDI event categories.
enum MidiEventType {
    case noteOn
    case noteOff
    case controlChange
    case programChange
    case pitchBend
    case channelPressure
    case meta
    case sysEx
    case unknown
}

/// Protocol describing a normalized MIDI event.
protocol MidiEventProtocol {
    var timestamp: UInt32 { get }
    var type: MidiEventType { get }
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
    let channelNumber: UInt8
    let noteNumber: UInt8?
    let velocity: UInt8?
    let controllerValue: UInt32?

    var channel: UInt8? { channelNumber }
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

/// Represents SysEx events.
struct SysExEvent: MidiEventProtocol {
    let timestamp: UInt32
    let data: Data

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

    var type: MidiEventType { .unknown }
    var channel: UInt8? { nil }
    var noteNumber: UInt8? { nil }
    var velocity: UInt8? { nil }
    var controllerValue: UInt32? { nil }
    var metaType: UInt8? { nil }
    var rawData: Data? { data }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
