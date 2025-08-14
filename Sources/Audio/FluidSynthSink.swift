import Foundation
import CFluidSynth

// Refs: teatro-root

/// Audio sink based on the FluidSynth library. Acts as the default
/// backend on Linux systems and plays SoundFont (SF2) files.
public final class FluidSynthSink: MIDIAudioSink {
    private var settings: OpaquePointer?
    private var synth: OpaquePointer?
    private var driver: OpaquePointer?

    /// Create a sink and load the given SoundFont file.
    /// - Parameter sf2Path: Path to an SF2 sound font.
    public init(sf2Path: String) throws {
        let set = new_fluid_settings()
        #if os(macOS)
        fluid_settings_setstr(set, "audio.driver", "coreaudio")
        #else
        fluid_settings_setstr(set, "audio.driver", "pulseaudio")
        #endif
        let syn = new_fluid_synth(set)
        if fluid_synth_sfload(syn, sf2Path, 1) == FLUID_FAILED {
            delete_fluid_synth(syn)
            delete_fluid_settings(set)
            throw NSError(domain: "FluidSynthSink", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Failed to load \(sf2Path)"])
        }
        let drv = new_fluid_audio_driver(set, syn)
        self.settings = set
        self.synth = syn
        self.driver = drv
    }

    deinit {
        if let d = driver { delete_fluid_audio_driver(d) }
        if let s = synth { delete_fluid_synth(s) }
        if let set = settings { delete_fluid_settings(set) }
    }

    public func noteOn(note: UInt8, vel: UInt8, ch: UInt8) {
        guard let syn = synth else { return }
        fluid_synth_noteon(syn, Int32(ch), Int32(note), Int32(vel))
    }

    public func noteOff(note: UInt8, ch: UInt8) {
        guard let syn = synth else { return }
        fluid_synth_noteoff(syn, Int32(ch), Int32(note))
    }

    public func controlChange(cc: UInt8, value: UInt8, ch: UInt8) {
        // Control changes are currently ignored in this stub
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
