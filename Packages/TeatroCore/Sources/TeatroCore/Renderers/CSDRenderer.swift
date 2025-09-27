import Foundation

public struct CSDRenderer: RendererPlugin {
    public static let identifier = "csound"
    public static let fileExtensions = ["csd", "csound"]

    public static func renderToFile(_ score: CsoundScore, to path: String = "output.csd") {
        try? score.render().write(toFile: path, atomically: true, encoding: .utf8)
    }

    public static func render(view: Renderable, output: String?) throws {
        guard let score = view as? CsoundScore else { throw RendererError.unsupportedInput("Csound output requires a Csound score input") }
        renderToFile(score, to: output ?? "output.csd")
    }
}

@available(*, deprecated, renamed: "CSDRenderer")
public typealias CsoundRenderer = CSDRenderer

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
