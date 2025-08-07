import Foundation

/// Represents a Registered Parameter Number message with 32-bit data.
public struct RegisteredParameterNumber: MidiEventProtocol, Sendable, Equatable {
    public let timestamp: UInt32
    public let group: UInt8?
    public let channel: UInt8?
    /// 14-bit parameter number (MSB << 7 | LSB).
    public let parameter: UInt16
    /// 32-bit data value.
    public let value: UInt32

    public init(timestamp: UInt32 = 0,
                group: UInt8? = nil,
                channel: UInt8? = nil,
                parameter: UInt16,
                value: UInt32) {
        self.timestamp = timestamp
        self.group = group
        self.channel = channel
        self.parameter = parameter & 0x3FFF
        self.value = value
    }

    public var type: MidiEventType { .rpn }
    public var noteNumber: UInt8? { nil }
    public var velocity: UInt32? { nil }
    public var controllerValue: UInt32? { value }
    public var metaType: UInt8? { nil }
    public var rawData: Data? { nil }

    /// Approximates the value in the 14-bit MIDI 1.0 domain.
    public var midi1Value: UInt16 {
        UInt16(truncatingIfNeeded: value >> 18)
    }
}

/// Represents a Non-Registered Parameter Number message with 32-bit data.
public struct NonRegisteredParameterNumber: MidiEventProtocol, Sendable, Equatable {
    public let timestamp: UInt32
    public let group: UInt8?
    public let channel: UInt8?
    /// 14-bit parameter number (MSB << 7 | LSB).
    public let parameter: UInt16
    /// 32-bit data value.
    public let value: UInt32

    public init(timestamp: UInt32 = 0,
                group: UInt8? = nil,
                channel: UInt8? = nil,
                parameter: UInt16,
                value: UInt32) {
        self.timestamp = timestamp
        self.group = group
        self.channel = channel
        self.parameter = parameter & 0x3FFF
        self.value = value
    }

    public var type: MidiEventType { .nrpn }
    public var noteNumber: UInt8? { nil }
    public var velocity: UInt32? { nil }
    public var controllerValue: UInt32? { value }
    public var metaType: UInt8? { nil }
    public var rawData: Data? { nil }

    /// Approximates the value in the 14-bit MIDI 1.0 domain.
    public var midi1Value: UInt16 {
        UInt16(truncatingIfNeeded: value >> 18)
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
