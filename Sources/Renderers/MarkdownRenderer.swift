public struct MarkdownRenderer {
    public static func render(_ view: Renderable) -> String {
        "```\n" + view.render() + "\n```"
    }
}
