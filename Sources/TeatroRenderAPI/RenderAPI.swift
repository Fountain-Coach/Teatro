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
        var storyboard: Storyboard
        var normalizedUMP: Data? = nil

        if let dsl = input.storyboardDSL {
            storyboard = try StoryboardParser.parse(dsl)
            if let ump = input.umpData {
                let events = try UMPParser.parse(data: ump)
                let words = UMPEncoder.encodeEvents(events)
                normalizedUMP = dataFromWords(words)
            }
        } else if let ump = input.umpData {
            let events = try UMPParser.parse(data: ump)
            let words = UMPEncoder.encodeEvents(events)
            normalizedUMP = dataFromWords(words)
            let hexLines = words.map { String(format: "%08X", $0) }
            storyboard = Storyboard {
                Scene("UMP") {
                    Text(hexLines.joined(separator: "\n"))
                }
            }
        } else {
            throw RenderError.parse("no storyboard input provided")
        }

        let svgString = SVGAnimator.renderAnimatedSVG(storyboard: storyboard)
        guard let svgData = svgString.data(using: .utf8) else {
            throw RenderError.layout("unable to encode SVG")
        }

        return RenderResult(svg: svgData, markdown: nil, ump: normalizedUMP)
    }

    /// .session/log/markdown -> Markdown reflection + overlay markers
    public static func renderSession(_ input: RenderSessionInput) throws -> RenderResult {
        let session = SessionParser.parse(input.logText)
        let lines = session.text.split(separator: "\n", omittingEmptySubsequences: false)
        var overlays: [[String: Any]] = []
        for (idx, line) in lines.enumerated() {
            if line.hasPrefix("$ ") {
                overlays.append([
                    "line": idx + 1,
                    "command": String(line.dropFirst(2))
                ])
            }
        }

        var overlaySection = ""
        if !overlays.isEmpty {
            let data = try JSONSerialization.data(withJSONObject: overlays, options: [.prettyPrinted, .sortedKeys])
            if let json = String(data: data, encoding: .utf8) {
                overlaySection = "\n\n```json\n" + json + "\n```"
            }
        }

        let markdown = "```session\n" + session.text + "\n```" + overlaySection
        return RenderResult(markdown: markdown)
    }

    /// lightweight search/plan -> Markdown or small SVG panels
    public static func renderSearch(_ input: RenderSearchInput) throws -> RenderResult {
        let lines = input.query.split(separator: "\n", omittingEmptySubsequences: false)
        var items: [String] = []
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }
            if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
                items.append(trimmed)
            } else {
                items.append("- \(trimmed)")
            }
        }
        let markdown = items.joined(separator: "\n")
        return RenderResult(markdown: markdown)
    }

    private static func dataFromWords(_ words: [UInt32]) -> Data {
        var data = Data(capacity: words.count * 4)
        for word in words {
            var be = word.bigEndian
            withUnsafeBytes(of: &be) { buffer in
                data.append(buffer.bindMemory(to: UInt8.self))
            }
        }
        return data
    }
}
