import Foundation

public struct MIDINote {
    public let channel: Int
    public let note: Int
    public let velocity: Int
    public let duration: Double

    public init(channel: Int, note: Int, velocity: Int, duration: Double) {
        self.channel = channel
        self.note = note
        self.velocity = velocity
        self.duration = duration
    }
}

@resultBuilder
public enum NoteBuilder {
    public static func buildBlock(_ notes: MIDINote...) -> [MIDINote] {
        notes
    }
}

public struct MIDISequence: Renderable {
    public let notes: [MIDINote]

    public init(@NoteBuilder _ build: () -> [MIDINote]) {
        self.notes = build()
    }

    public func layout() -> LayoutNode {
        let lines = notes.map {
            "NOTE(ch:\($0.channel), key:\($0.note), vel:\($0.velocity), dur:\($0.duration))"
        }.joined(separator: "\n")
        return .raw(lines)
    }
}

public struct MIDIRenderer: RendererPlugin {
    public static let identifier = "midi"
    public static let fileExtensions = ["mid", "midi"]

    public static func renderToFile(_ sequence: MIDISequence, to path: String = "output.mid") {
        let content = sequence.notes.map {
            "NOTE(ch:\($0.channel), key:\($0.note), vel:\($0.velocity), dur:\($0.duration))"
        }.joined(separator: "\n")
        try? content.write(toFile: path, atomically: true, encoding: .utf8)
    }

    public static func render(view: Renderable, output: String?) throws {
        guard let seq = view as? MIDISequence else { throw RendererError.unsupportedInput("MIDI output requires a MIDISequence input") }
        renderToFile(seq, to: output ?? "output.mid")
    }
}
