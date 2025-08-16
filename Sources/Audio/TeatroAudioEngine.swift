#if canImport(AVFoundation)
import Foundation
import AVFoundation

/// Apple-specific audio engine backed by `AVAudioEngine` and `AVAudioUnitSampler`.
/// Loads a default SoundFont if available and exposes MIDI 1.0 style methods
/// via `MIDIAudioSink`.
public final class TeatroAudioEngine: MIDIAudioSink {
    private let engine = AVAudioEngine()
    private let sampler = AVAudioUnitSampler()

    public init() throws {
        engine.attach(sampler)
        engine.connect(sampler, to: engine.mainMixerNode, format: nil)
        try engine.start()
        let defaultSF2 = "/Library/Sounds/GeneralUser.sf2"
        if FileManager.default.fileExists(atPath: defaultSF2) {
            let url = URL(fileURLWithPath: defaultSF2)
            try? sampler.loadSoundBankInstrument(at: url, program: 0, bankMSB: 0x79, bankLSB: 0x00)
        }
    }

    public func noteOn(note: UInt8, vel: UInt8, ch: UInt8) {
        sampler.startNote(UInt8(note), withVelocity: UInt8(vel), onChannel: UInt8(ch))
    }

    public func noteOff(note: UInt8, ch: UInt8) {
        sampler.stopNote(UInt8(note), onChannel: UInt8(ch))
    }

    public func controlChange(cc: UInt8, value: UInt8, ch: UInt8) {
        sampler.sendController(UInt8(cc), withValue: UInt8(value), onChannel: UInt8(ch))
    }
}
#else
/// Fallback stub used on non-Apple platforms.
public final class TeatroAudioEngine: MIDIAudioSink {
    public init() throws {}
    public func noteOn(note: UInt8, vel: UInt8, ch: UInt8) {}
    public func noteOff(note: UInt8, ch: UInt8) {}
    public func controlChange(cc: UInt8, value: UInt8, ch: UInt8) {}
}
#endif

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
