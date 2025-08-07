import Foundation

/// MIDI Capability Inquiry message container.
public enum MIDICIMessage: Equatable {
    case discovery(MIDICIDiscovery)
    case profile(MIDICIProfileNegotiation)
    case property(MIDICIPropertyExchange)
}

/// MIDI-CI Discovery message.
public struct MIDICIDiscovery: Equatable {
    public let deviceID: UInt8
    public let payload: Data

    public init(deviceID: UInt8, payload: Data = Data()) {
        self.deviceID = deviceID
        self.payload = payload
    }

    /// Serializes the message to a SysEx byte stream.
    public func sysex() -> Data {
        var bytes: [UInt8] = [0xF0, 0x7E, deviceID, 0x0D, 0x70]
        bytes.append(contentsOf: payload)
        bytes.append(0xF7)
        return Data(bytes)
    }
}

/// MIDI-CI Profile negotiation message.
public struct MIDICIProfileNegotiation: Equatable {
    public let deviceID: UInt8
    public let payload: Data

    public init(deviceID: UInt8, payload: Data = Data()) {
        self.deviceID = deviceID
        self.payload = payload
    }

    public func sysex() -> Data {
        var bytes: [UInt8] = [0xF0, 0x7E, deviceID, 0x0D, 0x72]
        bytes.append(contentsOf: payload)
        bytes.append(0xF7)
        return Data(bytes)
    }
}

/// MIDI-CI Property exchange message.
public struct MIDICIPropertyExchange: Equatable {
    public let deviceID: UInt8
    public let property: String
    public let value: Data?

    public init(deviceID: UInt8, property: String, value: Data? = nil) {
        self.deviceID = deviceID
        self.property = property
        self.value = value
    }

    public func sysex() -> Data {
        var bytes: [UInt8] = [0xF0, 0x7E, deviceID, 0x0D, 0x78]
        bytes.append(contentsOf: property.utf8)
        if let v = value { bytes.append(contentsOf: v) }
        bytes.append(0xF7)
        return Data(bytes)
    }
}

/// Parsing helpers for MIDI-CI messages.
public enum MIDICI {
    /// Parses a SysEx byte stream into a `MIDICIMessage`.
    /// The data must include the `F0`/`F7` markers.
    public static func parse(sysEx data: Data) -> MIDICIMessage? {
        let bytes = [UInt8](data)
        guard bytes.count >= 6,
              bytes.first == 0xF0,
              bytes.last == 0xF7,
              bytes[3] == 0x0D else { return nil }
        let deviceID = bytes[2]
        let subID2 = bytes[4]
        let payload = Data(bytes[5..<(bytes.count - 1)])
        switch subID2 {
        case 0x70:
            return .discovery(MIDICIDiscovery(deviceID: deviceID, payload: payload))
        case 0x72:
            return .profile(MIDICIProfileNegotiation(deviceID: deviceID, payload: payload))
        case 0x78:
            let prop = String(data: payload, encoding: .utf8) ?? ""
            return .property(MIDICIPropertyExchange(deviceID: deviceID, property: prop, value: nil))
        default:
            return nil
        }
    }

    /// Serializes a `MIDICIMessage` into SysEx data.
    public static func serialize(_ message: MIDICIMessage) -> Data {
        switch message {
        case .discovery(let d): return d.sysex()
        case .profile(let p): return p.sysex()
        case .property(let p): return p.sysex()
        }
    }
}
