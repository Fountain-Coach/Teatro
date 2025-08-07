public struct MarkdownRenderer: RendererPlugin {
    public static let identifier = "markdown"
    public static let fileExtensions = ["md", "markdown"]

    public static func render(_ view: Renderable) -> String {
        let body = view.layout().lines().map { StyleExpander.markdown($0) }.joined(separator: "\n")
        return "```\n" + body + "\n```"
    }

    public static func render(view: Renderable, output: String?) throws {
        let result = render(view)
        try write(result, to: output, defaultName: "output.md")
    }
}
