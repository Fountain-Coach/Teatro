import Foundation

/// A type-erased `Codable` value used to encode and decode arbitrary JSON.
public struct AnyCodable: Codable {
    public let value: Any

    public init(_ value: Any) {
        self.value = value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if container.decodeNil() {
            value = ()
        } else if var unkeyed = try? decoder.unkeyedContainer() {
            var array: [Any] = []
            while !unkeyed.isAtEnd {
                let decoded = try unkeyed.decode(AnyCodable.self)
                array.append(decoded.value)
            }
            value = array
        } else if let keyed = try? decoder.container(keyedBy: CodingKeys.self) {
            var dict: [String: Any] = [:]
            for key in keyed.allKeys {
                let decoded = try keyed.decode(AnyCodable.self, forKey: key)
                dict[key.stringValue] = decoded.value
            }
            value = dict
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported JSON value")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            var unkeyed = encoder.unkeyedContainer()
            for element in array {
                let value = AnyCodable(element)
                try unkeyed.encode(value)
            }
        case let dict as [String: Any]:
            var keyed = encoder.container(keyedBy: CodingKeys.self)
            for (key, val) in dict {
                try keyed.encode(AnyCodable(val), forKey: CodingKeys(stringValue: key)!)
            }
        default:
            try container.encodeNil()
        }
    }

    private struct CodingKeys: CodingKey {
        var stringValue: String
        init?(stringValue: String) { self.stringValue = stringValue }
        var intValue: Int? { nil }
        init?(intValue: Int) { return nil }
    }
}
