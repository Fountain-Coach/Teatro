import Foundation

/// Manages discovery and selection of MIDI2 endpoints for preview routing.
/// Currently placeholder; provides an in-memory selection without CoreMIDI IO.
public final class MIDIEndpointManager: @unchecked Sendable {
    public struct Endpoint: Sendable, Equatable { public let id: String; public let name: String }

    private var endpoints: [Endpoint] = [Endpoint(id: "virtual-0", name: "Virtual Preview Endpoint")]
    private var selected: Endpoint?

    public init() {}

    public func availableEndpoints() -> [Endpoint] { endpoints }
    public func selectedEndpoint() -> Endpoint? { selected }
    public func select(_ endpoint: Endpoint) { selected = endpoint }
}
