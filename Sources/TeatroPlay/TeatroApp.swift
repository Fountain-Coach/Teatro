import Foundation
import ArgumentParser
import Teatro

struct TeatroApp {
    struct Options: ParsableArguments {
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
    }

    let options: Options

    init() throws {
        self.options = try Options.parse()
    }

    func run() async throws {
        let data: Data
        if let path = options.input {
            data = try Data(contentsOf: URL(fileURLWithPath: path))
        } else if options.fromStdin {
            data = FileHandle.standardInput.readDataToEndOfFile()
        } else {
            throw ValidationError("Provide --input or --from-stdin")
        }

        let audioSink: MIDIAudioSink
        switch options.sink.lowercased() {
        case "fluidsynth":
            let font = options.sf2 ?? "assets/example.sf2"
            audioSink = try FluidSynthSink(sf2Path: font)
        case "sfizz":
            let preset = options.sfz ?? ""
            audioSink = SfizzSink(sfzPath: preset)
        default:
            throw ValidationError("Unsupported sink \(options.sink)")
        }

        if data.count % 4 == 0 {
            try MIDI1Bridge.umpToMIDI1(data, sink: audioSink)
        } else {
            let words = MIDI1Bridge.midi1ToUMP(data)
            var umpData = Data()
            for w in words {
                var be = w.bigEndian
                withUnsafeBytes(of: &be) { umpData.append(contentsOf: $0) }
            }
            try MIDI1Bridge.umpToMIDI1(umpData, sink: audioSink)
        }
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
