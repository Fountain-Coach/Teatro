import Foundation

public struct MidiEventView: Renderable {
    public let events: [any MidiEventProtocol]

    public init(events: [any MidiEventProtocol]) {
        self.events = events
    }

    public func layout() -> LayoutNode {
        let lines = events.map { event -> String in
            var parts: [String] = ["t\(event.timestamp)"]
            if let ch = event.channel { parts.append("ch\(ch)") }
            switch event.type {
            case .noteOn:
                parts.append("noteOn \(event.noteNumber ?? 0) v\(event.velocity ?? 0)")
            case .noteOff:
                parts.append("noteOff \(event.noteNumber ?? 0)")
            case .controlChange:
                parts.append("cc \(event.noteNumber ?? 0) \(event.controllerValue ?? 0)")
            case .programChange:
                parts.append("program \(event.controllerValue ?? 0)")
            case .pitchBend:
                parts.append("pitch \(event.controllerValue ?? 0)")
            case .channelPressure:
                parts.append("pressure \(event.controllerValue ?? 0)")
            case .polyphonicKeyPressure:
                parts.append("polyPressure \(event.noteNumber ?? 0) v\(event.velocity ?? 0)")
            case .perNoteController:
                let ctrl = (event as? PerNoteControllerEvent)?.controllerIndex ?? 0
                parts.append("pnc \(event.noteNumber ?? 0) c\(ctrl) \(event.controllerValue ?? 0)")
            case .jrTimestamp:
                parts.append("jr \(event.controllerValue ?? 0)")
            case .meta:
                let meta = event.metaType.map { String(format: "%02X", $0) } ?? "??"
                parts.append("meta \(meta)")
            case .sysEx:
                parts.append("sysex \(event.rawData?.count ?? 0) bytes")
            case .unknown:
                parts.append("unknown")
            }
            return parts.joined(separator: " ")
        }.joined(separator: "\n")
        return .raw(lines)
    }
}
