import Foundation

// Refs: teatro-root

/// Reliability helper tracking ACK/NACK state with a retransmit ring buffer
/// and receive window. Designed for MIDI-based SSE transport.
public actor FountainSSEReliability {

    /// Hooks for observing reliability metrics.
    /// Each closure is invoked on the actor's isolated context.
    public struct MetricsHooks: Sendable {
        public var onRTT: (@Sendable (TimeInterval) async -> Void)?
        public var onLoss: (@Sendable (UInt64) async -> Void)?
        public var onWindowDepth: (@Sendable (Int) async -> Void)?

        public init(
            onRTT: (@Sendable (TimeInterval) async -> Void)? = nil,
            onLoss: (@Sendable (UInt64) async -> Void)? = nil,
            onWindowDepth: (@Sendable (Int) async -> Void)? = nil
        ) {
            self.onRTT = onRTT
            self.onLoss = onLoss
            self.onWindowDepth = onWindowDepth
        }
    }

    private struct Pending: Sendable {
        var env: FountainSSEEnvelope
        var timestamp: Date
    }

    /// Sent envelopes awaiting ACK.
    private var pending: [UInt64: Pending] = [:]

    /// Max number of outstanding envelopes to keep in the ring buffer.
    private let capacity: Int

    // Receive window tracking.
    private var recvBase: UInt64 = 0
    private var received: Set<UInt64> = []

    private var hooks: MetricsHooks

    public init(windowSize: Int = 32, hooks: MetricsHooks = .init()) {
        self.capacity = windowSize
        self.hooks = hooks
    }

    /// Register a sent envelope for tracking.
    @discardableResult
    public func sent(_ env: FountainSSEEnvelope, at date: Date = Date()) async -> UInt64 {
        pending[env.seq] = Pending(env: env, timestamp: date)
        trim()
        await hooks.onWindowDepth?(pending.count)
        return env.seq
    }

    /// Process an ACK for a sequence number.
    @discardableResult
    public func ack(_ seq: UInt64, at date: Date = Date()) async -> FountainSSEEnvelope? {
        guard let entry = pending.removeValue(forKey: seq) else { return nil }
        await hooks.onWindowDepth?(pending.count)
        await hooks.onRTT?(date.timeIntervalSince(entry.timestamp))
        return entry.env
    }

    /// Process a NACK for a sequence number and return the payload to retransmit.
    public func nack(_ seq: UInt64) async -> FountainSSEEnvelope? {
        guard let entry = pending[seq] else { return nil }
        await hooks.onLoss?(seq)
        return entry.env
    }

    /// Update receiver state for an incoming sequence number. Returns ACK and any NACKs.
    public func receive(_ seq: UInt64) -> (ack: UInt64, nacks: [UInt64]) {
        if recvBase == 0 { recvBase = seq }

        var nacks: [UInt64] = []
        if seq > recvBase {
            for missing in recvBase..<seq {
                if !received.contains(missing) {
                    nacks.append(missing)
                }
            }
        }

        received.insert(seq)
        while received.contains(recvBase) {
            received.remove(recvBase)
            recvBase &+= 1
        }

        return (ack: seq, nacks: nacks)
    }

    private func trim() {
        while pending.count > capacity {
            if let oldest = pending.keys.sorted().first {
                pending.removeValue(forKey: oldest)
            }
        }
    }
}

