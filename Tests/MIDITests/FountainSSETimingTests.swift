import XCTest
@testable import Teatro

// Refs: teatro-root

final class FountainSSETimingTests: XCTestCase {
    func testScheduleRounding() {
        let now = Date()
        let nowJR: UInt32 = 0
        let futureJR = FountainSSETiming.jrTimestamp(fromMilliseconds: 10.4)
        let (playout, late) = FountainSSETiming.schedule(
            jrTimestamp: futureJR,
            nowJR: nowJR,
            arrival: now,
            targetPlayoutMs: 2
        )
        XCTAssertFalse(late)
        let deltaMs = playout.timeIntervalSince(now) * 1000
        XCTAssertEqual(deltaMs, 11, accuracy: 0.001)
    }

    func testLatePacketDetection() {
        let now = Date()
        let nowJR: UInt32 = 0
        let nearJR = FountainSSETiming.jrTimestamp(fromMilliseconds: 1)
        let (playout, late) = FountainSSETiming.schedule(
            jrTimestamp: nearJR,
            nowJR: nowJR,
            arrival: now,
            targetPlayoutMs: 3
        )
        XCTAssertTrue(late)
        let deltaMs = playout.timeIntervalSince(now) * 1000
        XCTAssertEqual(deltaMs, 3, accuracy: 0.001)
    }

    func testScheduleWithoutTimestamp() {
        let now = Date()
        let (playout, late) = FountainSSETiming.schedule(
            jrTimestamp: nil,
            nowJR: 0,
            arrival: now,
            targetPlayoutMs: 5
        )
        XCTAssertFalse(late)
        let deltaMs = playout.timeIntervalSince(now) * 1000
        XCTAssertEqual(deltaMs, 5, accuracy: 0.001)
    }
}

