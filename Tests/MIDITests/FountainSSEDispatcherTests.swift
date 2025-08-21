import XCTest
@testable import Teatro

// Refs: teatro-root

final class FountainSSEDispatcherTests: XCTestCase {
    func testFragmentationAndOutOfOrderDelivery() async throws {
        let dispatcher = FountainSSEDispatcher()

        // Sequence 2 arrives first as a complete Flex packet.
        let env2 = FountainSSEEnvelope(ev: .message, seq: 2, data: "World")
        let seq2Data = try env2.encodeJSON()

        // Sequence 1 is fragmented across two SysEx8 packets delivered out of order.
        let fragB = FountainSSEEnvelope(
            ev: .message,
            seq: 1,
            frag: .init(i: 1, n: 2),
            data: "lo"
        )
        let fragA = FountainSSEEnvelope(
            ev: .message,
            seq: 1,
            frag: .init(i: 0, n: 2),
            data: "Hel"
        )
        let fragBData = try fragB.encodeJSON()
        let fragAData = try fragA.encodeJSON()

        try await dispatcher.receiveFlex(seq2Data)
        try await dispatcher.receiveSysEx8(fragBData)
        try await dispatcher.receiveSysEx8(fragAData)

        var iterator = dispatcher.events.makeAsyncIterator()
        let first = await iterator.next()
        XCTAssertEqual(first?.seq, 1)
        XCTAssertEqual(first?.data, "Hello")

        let second = await iterator.next()
        XCTAssertEqual(second?.seq, 2)
        XCTAssertEqual(second?.data, "World")
    }

    func testInOrderFragmentReassembly() async throws {
        let dispatcher = FountainSSEDispatcher()
        let fragA = FountainSSEEnvelope(
            ev: .message,
            seq: 1,
            frag: .init(i: 0, n: 2),
            data: "Hel"
        )
        let fragB = FountainSSEEnvelope(
            ev: .message,
            seq: 1,
            frag: .init(i: 1, n: 2),
            data: "lo"
        )
        try await dispatcher.receiveSysEx8(fragA.encodeJSON())
        try await dispatcher.receiveSysEx8(fragB.encodeJSON())
        var iterator = dispatcher.events.makeAsyncIterator()
        let assembled = await iterator.next()
        XCTAssertEqual(assembled?.data, "Hello")
    }
}

