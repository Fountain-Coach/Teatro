import Foundation

public struct CsoundRenderer {
    public static func renderToFile(_ score: CsoundScore, to path: String = "output.csd") {
        try? score.render().write(toFile: path, atomically: true, encoding: .utf8)
    }
}
