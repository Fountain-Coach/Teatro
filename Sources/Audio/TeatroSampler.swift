import Foundation

/// Shared protocol for all sampler implementations.
public protocol SampleSource: Sendable {
    func noteOn(_ note: Midi2NoteOn) async throws
    func noteOff(_ note: Midi2NoteOff) async throws
    func stopAll() async
    func loadInstrument(_ path: String) async throws
}

/// Available backend options for the sampler.
public enum SamplerBackend {
    case fluidsynth(sf2Path: String)
    case csound(orchestra: String)
}

/// Main Teatro sampler actor routing note events to the selected backend.
public actor TeatroSampler: SampleSource {
    private let impl: SampleSource

    /// Create a sampler using one of the supported backends.
    public init(backend: SamplerBackend) async throws {
        switch backend {
        case .fluidsynth(let sf2):
            let f = FluidSynthSampler()
            try await f.loadInstrument(sf2)
            self.impl = f
        case .csound(let orc):
            let c = CsoundSampler()
            try await c.loadInstrument(orc)
            self.impl = c
        }
    }

    /// Internal initializer for unit tests to provide a custom implementation.
    init(implementation: SampleSource) {
        self.impl = implementation
    }

    public func noteOn(_ note: Midi2NoteOn) async throws {
        try await impl.noteOn(note)
    }

    public func noteOff(_ note: Midi2NoteOff) async throws {
        try await impl.noteOff(note)
    }

    public func stopAll() async {
        await impl.stopAll()
    }

    public func loadInstrument(_ path: String) async throws {
        try await impl.loadInstrument(path)
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
