import Foundation

// Refs: teatro-root

/// JR timestamp helpers and jitter-buffered playout scheduling.
public struct FountainSSETiming {
    /// JR clock ticks per second (10.22 fixed-point format).
    public static let ticksPerSecond: Double = 4_194_304
    /// Milliseconds represented by a single JR tick.
    public static let msPerTick: Double = 1000.0 / ticksPerSecond
    public static let secondsPerTick: Double = 1.0 / ticksPerSecond

    public init() {}

    /// Convert a JR timestamp delta to milliseconds.
    public static func milliseconds(fromJRTimestamp ts: UInt32) -> Double {
        Double(ts) * msPerTick
    }

    /// Convert milliseconds to JR timestamp ticks.
    public static func jrTimestamp(fromMilliseconds ms: Double) -> UInt32 {
        UInt32(ms / msPerTick)
    }

    /// Compute playout time with a jitter buffer. Returns the scheduled `Date`
    /// and whether the packet arrived too late to meet `targetPlayoutMs`.
    /// - Parameters:
    ///   - jrTimestamp: Optional JR timestamp of the packet relative to `nowJR`.
    ///   - nowJR: Current JR clock reading when the packet was received.
    ///   - arrival: Local arrival time for reference.
    ///   - targetPlayoutMs: Desired playout delay in milliseconds.
    public static func schedule(
        jrTimestamp: UInt32?,
        nowJR: UInt32,
        arrival: Date = Date(),
        targetPlayoutMs: Double
    ) -> (playout: Date, late: Bool) {
        if let jr = jrTimestamp {
            let diffTicks = Int64(UInt64(jr) &- UInt64(nowJR))
            let deltaMs = Double(diffTicks) * msPerTick
            if deltaMs < targetPlayoutMs {
                let rounded = ceil(targetPlayoutMs)
                let time = arrival.addingTimeInterval(rounded / 1000)
                return (time, true)
            } else {
                let rounded = ceil(deltaMs)
                let time = arrival.addingTimeInterval(rounded / 1000)
                return (time, false)
            }
        } else {
            let rounded = ceil(targetPlayoutMs)
            let time = arrival.addingTimeInterval(rounded / 1000)
            return (time, false)
        }
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
