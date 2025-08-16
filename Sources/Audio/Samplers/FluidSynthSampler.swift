import Foundation
import CFluidSynth

/// FluidSynth-based sampler using libfluidsynth for realtime SoundFont playback.
public actor FluidSynthSampler: SampleSource {
    private var settings: OpaquePointer?
    private var synth: OpaquePointer?
    private var driver: OpaquePointer?

    public init() {}

    deinit {
        if let d = driver { delete_fluid_audio_driver(d) }
        if let s = synth { delete_fluid_synth(s) }
        if let set = settings { delete_fluid_settings(set) }
    }

    /// Loads a SoundFont file and initializes the audio driver.
    public func loadInstrument(_ path: String) async throws {
        await stopAll()

        let set = new_fluid_settings()
#if os(macOS)
        fluid_settings_setstr(set, "audio.driver", "coreaudio")
#else
        fluid_settings_setstr(set, "audio.driver", "pulseaudio")
#endif
        let syn = new_fluid_synth(set)
        if fluid_synth_sfload(syn, path, 1) == FLUID_FAILED {
            delete_fluid_synth(syn)
            delete_fluid_settings(set)
            throw NSError(domain: "FluidSynth", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to load \(path)"])
        }
        let drv = new_fluid_audio_driver(set, syn)

        self.settings = set
        self.synth = syn
        self.driver = drv
    }

    /// Sends a MIDI 2.0 Note On event to the synth.
    public func noteOn(_ note: Midi2NoteOn) async throws {
        guard let syn = synth else { return }
        let vel32 = UInt32(note.velocity) << 16
        fluid_synth_noteon(
            syn,
            Int32(note.channel.rawValue),
            Int32(note.note.rawValue),
            Int32(MIDI.midi1Velocity(from: vel32))
        )
    }

    /// Sends a MIDI 2.0 Note Off event to the synth.
    public func noteOff(_ note: Midi2NoteOff) async throws {
        guard let syn = synth else { return }
        fluid_synth_noteoff(
            syn,
            Int32(note.channel.rawValue),
            Int32(note.noteNumber.rawValue)
        )
    }

    /// Stops all notes and shuts down the audio driver.
    public func stopAll() async {
        if let syn = synth { fluid_synth_all_notes_off(syn, -1) }
        if let d = driver { delete_fluid_audio_driver(d); driver = nil }
        if let s = synth { delete_fluid_synth(s); synth = nil }
        if let set = settings { delete_fluid_settings(set); settings = nil }
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
