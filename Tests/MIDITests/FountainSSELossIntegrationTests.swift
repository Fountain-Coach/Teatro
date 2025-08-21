import XCTest
@testable import Teatro

// Refs: teatro-root

final class FountainSSELossIntegrationTests: XCTestCase {
    func testReliabilityRecoversFromLoss() async throws {
        let dispatcher = FountainSSEDispatcher()
        let sender = FountainSSEReliability(windowSize: 32)
        let receiver = FountainSSEReliability(windowSize: 32)

        let total = 100
        let losses: Set<Int> = [5, 23, 67, 89] // ~4% loss
        let reference = (1...total).map(String.init).joined(separator: " ")

        func deliver(_ env: FountainSSEEnvelope) async throws {
            let result = await receiver.receive(env.seq)
            try await dispatcher.receiveFlex(env.encodeJSON())
            await sender.ack(result.ack)
            for n in result.nacks {
                if let resend = await sender.nack(n) {
                    try await deliver(resend)
                }
            }
        }

        for seq in 1...total {
            let env = FountainSSEEnvelope(ev: .message, seq: UInt64(seq), data: "\(seq)".data(using: .utf8))
            await sender.sent(env)
            if !losses.contains(seq) {
                try await deliver(env)
            }
        }

        var iterator = dispatcher.events.makeAsyncIterator()
        var pieces: [String] = []
        for _ in 1...total {
            if let env = await iterator.next(), let d = env.data,
               let s = String(data: d, encoding: .utf8) {
                pieces.append(s)
            }
        }
        let result = pieces.joined(separator: " ")
        XCTAssertEqual(result, reference)
    }
}

