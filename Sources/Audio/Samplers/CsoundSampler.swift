import Foundation
import CCsound

extension OpaquePointer: @retroactive @unchecked Sendable {}

/// Csound-based sampler using libcsound for realtime playback.
public actor CsoundSampler: SampleSource {
    private var csound: OpaquePointer?
    private var performTask: Task<Void, Never>?

    public init() {}

    deinit {
        performTask?.cancel()
        if let cs = csound {
            csoundStop(cs)
            csoundReset(cs)
            csoundDestroy(cs)
        }
    }

    /// Loads a Csound orchestra file and prepares the engine.
    public func loadInstrument(_ path: String) async throws {
        await stopAll()
        let orc = try String(contentsOf: URL(fileURLWithPath: path), encoding: .utf8)
        let cs = csoundCreate(nil)
        csoundSetOption(cs, "-d")             // no displays
        csoundSetOption(cs, "-odac")          // output to device
        csoundCompileOrc(cs, orc)
        csoundStart(cs)
        self.csound = cs
        self.performTask = Task.detached { [cs] in
            while !Task.isCancelled && csoundPerformKsmps(cs) == 0 {}
        }
    }

    /// Sends a note on event using Csound score messages.
    public func noteOn(_ note: Midi2NoteOn) async throws {
        guard let cs = csound else { return }
        let freq = 440.0 * pow(2.0, (Double(note.note.rawValue) - 69.0) / 12.0)
        let amp = Double(note.velocity) / Double(UInt16.max)
        let msg = String(format: "i1 0 1 %.3f %.3f", amp, freq)
        csoundInputMessage(cs, msg)
    }

    /// Csound notes terminate based on duration; explicit Note Off is a no-op.
    public func noteOff(_ note: Midi2NoteOff) async throws { }

    /// Stops audio playback and resets the engine.
    public func stopAll() async {
        performTask?.cancel()
        performTask = nil
        if let cs = csound {
            csoundStop(cs)
            csoundReset(cs)
        }
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
