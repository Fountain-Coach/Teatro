import XCTest
@testable import Teatro

final class MIDICIFountainSSETests: XCTestCase {
    final class MockPeer {
        var enabledProfiles: Set<String> = []
        var properties: [String: Data] = [:]

        func receive(_ message: MIDICIMessage) {
            switch message {
            case .profile(let negotiation):
                if negotiation.operation == .enable {
                    enabledProfiles.insert(negotiation.profile)
                } else {
                    enabledProfiles.remove(negotiation.profile)
                }
            case .property(let exchange):
                properties[exchange.property] = exchange.value
            case .discovery:
                break
            }
        }
    }

    private func send(_ message: MIDICIMessage, to peer: MockPeer) throws {
        let sysEx = MIDICI.serialize(message)
        let event = SysExEvent(timestamp: 0, data: sysEx, group: 0)
        let words = UMPEncoder.encodeEvent(event, defaultGroup: 0)
        var data = Data()
        for word in words {
            var be = word.bigEndian
            withUnsafeBytes(of: &be) { data.append(contentsOf: $0) }
        }
        let parsed = try UMPParser.parse(data: data)
        guard let parsedEvent = parsed.first else { return }
        if let msg = MIDICIDispatcher.dispatch(event: parsedEvent) {
            peer.receive(msg)
        }
    }

    func testEnableDisableAndPropertyRoundTrip() throws {
        MIDICIDispatcher.enabledProfiles.removeAll()
        let peer = MockPeer()
        try send(.profile(FountainSSEProfile.enable(deviceID: 0x01)), to: peer)
        XCTAssertTrue(peer.enabledProfiles.contains(FountainSSEProfile.id))
        XCTAssertTrue(MIDICIDispatcher.enabledProfiles.contains(FountainSSEProfile.id))

        let url = "wss://example.com"
        let value = FountainSSEProperties.encodeEndpoint(url)
        let prop = MIDICIPropertyExchange(deviceID: 0x01, property: FountainSSEProperties.endpointURL, value: value)
        try send(.property(prop), to: peer)
        XCTAssertEqual(peer.properties[FountainSSEProperties.endpointURL], value)

        try send(.profile(FountainSSEProfile.disable(deviceID: 0x01)), to: peer)
        XCTAssertFalse(peer.enabledProfiles.contains(FountainSSEProfile.id))
        XCTAssertFalse(MIDICIDispatcher.enabledProfiles.contains(FountainSSEProfile.id))
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
