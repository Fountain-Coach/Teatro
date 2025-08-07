public struct HTMLRenderer: RendererPlugin {
    public static let identifier = "html"
    public static let fileExtensions = ["html"]

    public static func render(_ view: Renderable) -> String {
        let body = view.layout().lines().map { StyleExpander.html($0) }.joined(separator: "\n")
        return "<html><body><pre>\n" + body + "\n</pre></body></html>"
    }

    public static func render(view: Renderable, output: String?) throws {
        let result = render(view)
        try write(result, to: output, defaultName: "output.html")
    }
}
