import Foundation

public struct UMPRenderer: RendererPlugin {
    public static let identifier = "ump"
    public static let fileExtensions: [String] = []

    public static func render(view: Renderable, output: String?) throws {
        guard let midiView = view as? MidiEventView else { throw RendererError.unsupportedInput("UMP output requires MIDI or UMP input") }
        let words = UMPEncoder.encodeEvents(midiView.events)
        var data = Data()
        for word in words {
            var be = word.bigEndian
            withUnsafeBytes(of: &be) { data.append(contentsOf: $0) }
        }
        try writeData(data, to: output, defaultName: "output.ump")
    }
}
