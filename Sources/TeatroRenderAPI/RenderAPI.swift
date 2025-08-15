import Foundation
import Teatro

public struct RenderResult {
    public let svg: Data?
    public let markdown: String?
    public let ump: Data?

    public init(svg: Data? = nil, markdown: String? = nil, ump: Data? = nil) {
        self.svg = svg
        self.markdown = markdown
        self.ump = ump
    }
}

public enum TeatroRenderer {
    /// .fountain -> SVG (+ optional Markdown synopsis)
    public static func renderScript(_ input: RenderScriptInput) throws -> RenderResult {
        let text = input.fountainText

        // Parse fountain to gather synopsis lines
        let parser = FountainParser()
        let nodes = parser.parse(text)
        let synopsisLines = nodes.compactMap { node -> String? in
            if case .synopsis = node.type {
                var text = node.rawText.trimmingCharacters(in: .whitespaces)
                if text.hasPrefix("=") {
                    text.removeFirst()
                    text = text.trimmingCharacters(in: .whitespaces)
                }
                return "- \(text)"
            }
            return nil
        }
        let synopsis = synopsisLines.isEmpty ? nil : synopsisLines.joined(separator: "\n")

        // Layout to SVG using existing renderer
        let view = FountainSceneView(fountainText: text)
        let svgString = SVGRenderer.render(view)
        guard let svgData = svgString.data(using: .utf8) else {
            throw RenderError.layout("unable to encode SVG")
        }

        return RenderResult(svg: svgData, markdown: synopsis)
    }

    /// .ump / storyboard DSL -> animated SVG + (re)emitted .ump
    public static func renderStoryboard(_ input: RenderStoryboardInput) throws -> RenderResult {
        // 1) Parse UMP or Storyboard DSL
        // 2) Layout to animated SVG
        // 3) Return normalized UMP
        throw RenderError.unsupported("stub")
    }

    /// .session/log/markdown -> Markdown reflection + overlay markers
    public static func renderSession(_ input: RenderSessionInput) throws -> RenderResult {
        // 1) Parse session log
        // 2) Produce Markdown with overlays
        throw RenderError.unsupported("stub")
    }

    /// lightweight search/plan -> Markdown or small SVG panels
    public static func renderSearch(_ input: RenderSearchInput) throws -> RenderResult {
        // 1) Search and layout
        throw RenderError.unsupported("stub")
    }
}
