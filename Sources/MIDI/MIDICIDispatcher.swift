import Foundation

/// Routes SysEx events through the MIDI-CI parser.
public struct MIDICIDispatcher {
    /// Attempts to interpret a parsed MIDI event as a MIDI-CI message.
    /// - Parameter event: A `MidiEventProtocol` value, typically produced by `UMPParser`.
    /// - Returns: A `MIDICIMessage` if the event is a valid MIDI-CI SysEx packet.
    public static func dispatch(event: any MidiEventProtocol) -> MIDICIMessage? {
        guard event.type == .sysEx, let raw = event.rawData else { return nil }
        let bytes = [UInt8](raw)
        guard bytes.first == 0xF0, bytes.last == 0xF7 else { return nil }
        return MIDICI.parse(sysEx: raw)
    }
}
