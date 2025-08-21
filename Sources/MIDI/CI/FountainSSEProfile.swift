import Foundation

// Refs: teatro-root

/// MIDI-CI profile identifiers and helpers for Fountain SSE transport.
public enum FountainSSEProfile {
    /// Identifier string used during profile negotiation.
    public static let id = "fountain.sse"

    /// Build an enable profile negotiation message.
    public static func enable(deviceID: UInt8, functionBlock: UInt8 = 0) -> MIDICIProfileNegotiation {
        MIDICIProfileNegotiation(
            deviceID: deviceID,
            functionBlock: functionBlock,
            operation: .enable,
            profile: id
        )
    }

    /// Build a disable profile negotiation message.
    public static func disable(deviceID: UInt8, functionBlock: UInt8 = 0) -> MIDICIProfileNegotiation {
        MIDICIProfileNegotiation(
            deviceID: deviceID,
            functionBlock: functionBlock,
            operation: .disable,
            profile: id
        )
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
