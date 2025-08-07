import XCTest
@testable import Teatro

final class MIDICITests: XCTestCase {
    func testDiscoveryRoundTrip() throws {
        let discovery = MIDICIDiscovery(deviceID: 0x01)
        let sysEx = discovery.sysex()
        let event = SysExEvent(timestamp: 0, data: sysEx, group: 0)
        let words = UMPEncoder.encodeEvent(event, defaultGroup: 0)
        var data = Data()
        for word in words {
            var be = word.bigEndian
            withUnsafeBytes(of: &be) { data.append(contentsOf: $0) }
        }
        let parsed = try UMPParser.parse(data: data)
        guard let parsedEvent = parsed.first else {
            return XCTFail("Expected event")
        }
        guard let msg = MIDICIDispatcher.dispatch(event: parsedEvent) else {
            return XCTFail("Expected MIDI-CI message")
        }
        guard case .discovery(let decoded) = msg else {
            return XCTFail("Expected discovery message")
        }
        XCTAssertEqual(decoded.deviceID, discovery.deviceID)
    }

    func testMalformedPacketIgnored() throws {
        let malformed = Data([0xF0, 0x7E, 0x01, 0x0D, 0x70]) // missing terminator
        let event = SysExEvent(timestamp: 0, data: malformed, group: 0)
        let words = UMPEncoder.encodeEvent(event, defaultGroup: 0)
        var data = Data()
        for word in words {
            var be = word.bigEndian
            withUnsafeBytes(of: &be) { data.append(contentsOf: $0) }
        }
        let parsed = try UMPParser.parse(data: data)
        guard let parsedEvent = parsed.first else {
            return XCTFail("Expected event")
        }
        let msg = MIDICIDispatcher.dispatch(event: parsedEvent)
        XCTAssertNil(msg)
    }

    func testPropertyExchangeRoundTrip() throws {
        let property = MIDICIPropertyExchange(deviceID: 0x02, property: "")
        let sysEx = property.sysex()
        let event = SysExEvent(timestamp: 0, data: sysEx, group: 0)
        let words = UMPEncoder.encodeEvent(event, defaultGroup: 0)
        var data = Data()
        for word in words {
            var be = word.bigEndian
            withUnsafeBytes(of: &be) { data.append(contentsOf: $0) }
        }
        let parsed = try UMPParser.parse(data: data)
        guard let parsedEvent = parsed.first else {
            return XCTFail("Expected event")
        }
        guard let msg = MIDICIDispatcher.dispatch(event: parsedEvent) else {
            return XCTFail("Expected MIDI-CI message")
        }
        guard case .property(let decoded) = msg else {
            return XCTFail("Expected property exchange message")
        }
        XCTAssertEqual(decoded.deviceID, property.deviceID)
    }
}
