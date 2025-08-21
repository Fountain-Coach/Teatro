import Foundation

// Refs: teatro-root

/// Dispatcher that assembles `FountainSSEEnvelope` fragments carried over
/// MIDI 2.0 Flex Data or SysEx8 packets and publishes complete envelopes in
/// sequence order using an async stream.
public actor FountainSSEDispatcher {
    /// Async stream of reassembled envelopes.
    public nonisolated let events: AsyncStream<FountainSSEEnvelope>

    private let continuation: AsyncStream<FountainSSEEnvelope>.Continuation

    /// Buffers for fragments keyed by sequence number.
    private var fragmentBuffers: [UInt64: [UInt32: FountainSSEEnvelope]] = [:]

    /// Completed envelopes waiting to be published in sequence order.
    private var ready: [UInt64: FountainSSEEnvelope] = [:]

    /// Next expected sequence number.
    private var nextSeq: UInt64?

    public init() {
        var cont: AsyncStream<FountainSSEEnvelope>.Continuation!
        self.events = AsyncStream<FountainSSEEnvelope> { c in
            cont = c
        }
        self.continuation = cont
    }

    /// Consume a Flex Data fragment.
    public func receiveFlex(_ data: Data) throws {
        try handle(data)
    }

    /// Consume a SysEx8 fragment.
    public func receiveSysEx8(_ data: Data) throws {
        try handle(data)
    }

    // MARK: - Internal helpers

    private func handle(_ data: Data) throws {
        let env = try decodeEnvelope(from: data)
        ingest(env)
    }

    private func decodeEnvelope(from data: Data) throws -> FountainSSEEnvelope {
        if let env = try? FountainSSEEnvelope.decodeJSON(data) {
            return env
        }
        return try FountainSSEEnvelope.decodeCBOR(data)
    }

    private func ingest(_ env: FountainSSEEnvelope) {
        if let frag = env.frag {
            var dict = fragmentBuffers[env.seq, default: [:]]
            dict[frag.i] = env
            fragmentBuffers[env.seq] = dict
            if dict.count == frag.n {
                // Reassemble fragments once all pieces are present.
                let ordered = dict.values.sorted { ($0.frag?.i ?? 0) < ($1.frag?.i ?? 0) }
                var merged = ordered.first!
                merged.frag = nil
                var combined = Data()
                combined.reserveCapacity(ordered.compactMap { $0.data?.count }.reduce(0, +))
                for part in ordered {
                    if let d = part.data {
                        combined.append(d)
                    }
                }
                merged.data = combined
                fragmentBuffers.removeValue(forKey: env.seq)
                ready[env.seq] = merged
                updateAndPublish(for: env.seq)
            }
        } else {
            ready[env.seq] = env
            updateAndPublish(for: env.seq)
        }
    }

    private func publishReady() {
        if nextSeq == nil {
            nextSeq = ready.keys.min()
        }
        while let seq = nextSeq, let env = ready[seq] {
            continuation.yield(env)
            ready.removeValue(forKey: seq)
            nextSeq = seq &+ 1
        }
    }

    private func updateAndPublish(for seq: UInt64) {
        if let current = nextSeq {
            if seq < current { nextSeq = seq }
            publishReady()
        } else {
            nextSeq = seq
        }
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.

