import Foundation

/// Minimal protocol for audio sinks that respond to MIDI 1.0-style events.
public protocol MIDIAudioSink {
    /// Trigger a note-on event.
    func noteOn(note: UInt8, vel: UInt8, ch: UInt8)
    /// Trigger a note-off event.
    func noteOff(note: UInt8, ch: UInt8)
    /// Send a controller change event.
    func controlChange(cc: UInt8, value: UInt8, ch: UInt8)
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
