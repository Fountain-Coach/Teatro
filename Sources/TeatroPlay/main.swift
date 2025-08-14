import Foundation
import ArgumentParser
import Teatro

// Refs: teatro-root

@main
struct TeatroPlay: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Play UMP or MIDI1 data through an audio sink"
    )

    @Flag(name: .long, help: "Read input from stdin")
    var fromStdin: Bool = false

    @Option(name: .long, help: "Input file path")
    var input: String?

    @Option(name: .long, help: "Audio sink to use (fluidsynth or sfizz)")
    var sink: String = "fluidsynth"

    @Option(name: .long, help: "Path to an SF2 SoundFont for FluidSynth")
    var sf2: String?

    @Option(name: .long, help: "Path to an SFZ preset for Sfizz")
    var sfz: String?

    func run() throws {
        let data: Data
        if let path = input {
            data = try Data(contentsOf: URL(fileURLWithPath: path))
        } else if fromStdin {
            data = FileHandle.standardInput.readDataToEndOfFile()
        } else {
            throw ValidationError("Provide --input or --from-stdin")
        }

        let audioSink: MIDIAudioSink
        switch sink.lowercased() {
        case "fluidsynth":
            let font = sf2 ?? "assets/example.sf2"
            audioSink = try FluidSynthSink(sf2Path: font)
        case "sfizz":
            let preset = sfz ?? ""
            audioSink = SfizzSink(sfzPath: preset)
        default:
            throw ValidationError("Unsupported sink \(sink)")
        }

        if data.count % 4 == 0 {
            try MIDI1Bridge.umpToMIDI1(data, sink: audioSink)
        } else {
            let words = MIDI1Bridge.midi1ToUMP(data)
            var umpData = Data()
            for w in words {
                let be = w.bigEndian
                umpData.append(UInt8(truncatingIfNeeded: be >> 24))
                umpData.append(UInt8(truncatingIfNeeded: be >> 16))
                umpData.append(UInt8(truncatingIfNeeded: be >> 8))
                umpData.append(UInt8(truncatingIfNeeded: be))
            }
            try MIDI1Bridge.umpToMIDI1(umpData, sink: audioSink)
        }
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
