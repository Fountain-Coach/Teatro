import Foundation

/// Minimal representation of a Flex envelope used for MIDI 2.0 messaging.
/// The structure mirrors the fields outlined in the Teatro Codex plan and
/// will be extended to map to `Fountain-Coach/midi2` types in follow-up work.
public struct FlexEnvelope {
    /// Envelope version.
    public var v: Int
    /// Timestamp in microseconds.
    public var ts: UInt64
    /// Correlation identifier.
    public var corr: String
    /// Intent string describing the semantic meaning of `body`.
    public var intent: String
    /// Arbitrary JSON body carried by the envelope.
    public var body: [String: Any]

    public init(v: Int, ts: UInt64, corr: String, intent: String, body: [String: Any]) {
        self.v = v
        self.ts = ts
        self.corr = corr
        self.intent = intent
        self.body = body
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.

