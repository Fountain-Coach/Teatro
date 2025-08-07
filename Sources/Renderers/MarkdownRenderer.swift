public struct MarkdownRenderer {
    public static func render(_ view: Renderable) -> String {
        let body = view.layout().lines().map { StyleExpander.markdown($0) }.joined(separator: "\n")
        return "```\n" + body + "\n```"
    }
}
