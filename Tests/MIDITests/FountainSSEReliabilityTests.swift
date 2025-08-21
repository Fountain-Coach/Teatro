import XCTest
@testable import Teatro

// Refs: teatro-root

final class FountainSSEReliabilityTests: XCTestCase {
    func testRetransmissionOnLoss() async throws {
        let store = MetricsStore()

        let sender = FountainSSEReliability(
            windowSize: 8,
            hooks: .init(
                onRTT: { await store.addRTT($0) },
                onLoss: { await store.addLoss($0) },
                onWindowDepth: { await store.addDepth($0) }
            )
        )

        let receiver = FountainSSEReliability(windowSize: 8)

        let env1 = FountainSSEEnvelope(ev: .message, seq: 1, data: "one")
        let env2 = FountainSSEEnvelope(ev: .message, seq: 2, data: "two")
        let env3 = FountainSSEEnvelope(ev: .message, seq: 3, data: "three")

        await sender.sent(env1, at: Date(timeIntervalSince1970: 0))
        await sender.sent(env2, at: Date(timeIntervalSince1970: 0))
        await sender.sent(env3, at: Date(timeIntervalSince1970: 0))

        // Deliver seq1
        let r1 = await receiver.receive(env1.seq)
        XCTAssertEqual(r1.ack, 1)
        XCTAssertTrue(r1.nacks.isEmpty)
        await sender.ack(r1.ack, at: Date(timeIntervalSince1970: 1))

        // Drop seq2

        // Deliver seq3 causing receiver to nack seq2
        let r3 = await receiver.receive(env3.seq)
        XCTAssertEqual(r3.ack, 3)
        XCTAssertEqual(r3.nacks, [2])
        await sender.ack(r3.ack, at: Date(timeIntervalSince1970: 1))

        // Sender retransmits seq2
        guard let resend = await sender.nack(2) else {
            return XCTFail("Expected retransmission for seq2")
        }
        let r2 = await receiver.receive(resend.seq)
        XCTAssertEqual(r2.ack, 2)
        XCTAssertTrue(r2.nacks.isEmpty)
        await sender.ack(r2.ack, at: Date(timeIntervalSince1970: 2))

        let rtts = await store.rtts
        let losses = await store.losses
        let depths = await store.depths

        XCTAssertEqual(losses, [2])
        XCTAssertEqual(depths.last, 0)
        XCTAssertEqual(rtts.first ?? -1, 1.0, accuracy: 0.0001)
    }
}

private actor MetricsStore {
    var rtts: [TimeInterval] = []
    var losses: [UInt64] = []
    var depths: [Int] = []

    func addRTT(_ v: TimeInterval) { rtts.append(v) }
    func addLoss(_ v: UInt64) { losses.append(v) }
    func addDepth(_ v: Int) { depths.append(v) }
}

