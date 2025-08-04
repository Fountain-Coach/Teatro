import Foundation

public struct CSDRenderer {
    public static func renderToFile(_ score: CsoundScore, to path: String = "output.csd") {
        try? score.render().write(toFile: path, atomically: true, encoding: .utf8)
    }
}

@available(*, deprecated, renamed: "CSDRenderer")
public typealias CsoundRenderer = CSDRenderer

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
