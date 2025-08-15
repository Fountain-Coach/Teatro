import Foundation

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
        // 1) Parse Fountain
        // 2) Layout to SVG
        // 3) Produce optional synopsis Markdown
        // return RenderResult(svg: svgData, markdown: synopsis)
        throw RenderError.unsupported("stub")
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
