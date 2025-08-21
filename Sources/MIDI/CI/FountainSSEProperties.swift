import Foundation

// Refs: teatro-root

/// Property identifiers for Fountain SSE profile exchange.
public enum FountainSSEProperties {
    /// Property describing the endpoint URL for SSE over MIDI.
    public static let endpointURL = "fountain.sse.endpoint"

    /// Encodes the endpoint URL string into property value data.
    public static func encodeEndpoint(_ url: String) -> Data {
        Data(url.utf8)
    }

    /// Decodes endpoint URL data from a property exchange.
    public static func decodeEndpoint(_ data: Data) -> String? {
        String(data: data, encoding: .utf8)
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
