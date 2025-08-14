import Foundation

// Refs: teatro-root

/// Placeholder audio sink for the sfizz backend. Currently acts as a no-op
/// implementation to allow callers to select an SFZ sink without failing to
/// build when sfizz is unavailable.
public final class SfizzSink: MIDIAudioSink {
    public init(sfzPath: String) {}
    public func noteOn(note: UInt8, vel: UInt8, ch: UInt8) {}
    public func noteOff(note: UInt8, ch: UInt8) {}
    public func controlChange(cc: UInt8, value: UInt8, ch: UInt8) {}
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
