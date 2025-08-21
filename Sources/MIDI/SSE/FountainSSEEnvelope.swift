import Foundation
import SwiftCBOR

/// Envelope for FountainAI Server-Sent Events transported over MIDI.
///
/// Version 1 schema:
/// ```json
/// {
///   "v": 1,
///   "ev": "message" | "error" | "done" | "ctrl",
///   "id": "optional",
///   "ct": "application/json",
///   "seq": 123456,
///   "frag": { "i": 0, "n": 3 },
///   "ts": 1724142123.123,
///   "data": "<payload or slice>"
/// }
/// ```
public struct FountainSSEEnvelope: Codable, Equatable, Sendable {
    public enum Event: String, Codable, Sendable {
        case message
        case error
        case done
        case ctrl
    }

    public struct Fragment: Codable, Equatable, Sendable {
        public var i: UInt32
        public var n: UInt32
        public init(i: UInt32, n: UInt32) {
            self.i = i
            self.n = n
        }
    }

    public var v: UInt16
    public var ev: Event
    public var id: String?
    public var ct: String?
    public var seq: UInt64
    public var frag: Fragment?
    public var ts: Double?
    public var data: String?

    public init(
        v: UInt16 = 1,
        ev: Event,
        id: String? = nil,
        ct: String? = nil,
        seq: UInt64,
        frag: Fragment? = nil,
        ts: Double? = nil,
        data: String? = nil
    ) {
        self.v = v
        self.ev = ev
        self.id = id
        self.ct = ct
        self.seq = seq
        self.frag = frag
        self.ts = ts
        self.data = data
    }

    enum CodingKeys: String, CodingKey {
        case v, ev, id, ct, seq, frag, ts, data
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let version = try container.decode(UInt16.self, forKey: .v)
        guard version == 1 else {
            throw DecodingError.dataCorruptedError(
                forKey: .v,
                in: container,
                debugDescription: "Unsupported envelope version \(version)"
            )
        }
        self.v = version
        self.ev = try container.decode(Event.self, forKey: .ev)
        self.id = try container.decodeIfPresent(String.self, forKey: .id)
        self.ct = try container.decodeIfPresent(String.self, forKey: .ct)
        self.seq = try container.decode(UInt64.self, forKey: .seq)
        self.frag = try container.decodeIfPresent(Fragment.self, forKey: .frag)
        self.ts = try container.decodeIfPresent(Double.self, forKey: .ts)
        self.data = try container.decodeIfPresent(String.self, forKey: .data)
    }

    // JSON helpers
    public func encodeJSON() throws -> Data {
        let encoder = JSONEncoder()
        return try encoder.encode(self)
    }

    public static func decodeJSON(_ data: Data) throws -> FountainSSEEnvelope {
        let decoder = JSONDecoder()
        return try decoder.decode(FountainSSEEnvelope.self, from: data)
    }

    // CBOR helpers
    public func encodeCBOR() throws -> Data {
        let encoder = CodableCBOREncoder()
        return try encoder.encode(self)
    }

    public static func decodeCBOR(_ data: Data) throws -> FountainSSEEnvelope {
        let decoder = CodableCBORDecoder()
        return try decoder.decode(FountainSSEEnvelope.self, from: data)
    }
}
