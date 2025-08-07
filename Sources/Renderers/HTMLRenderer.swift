public struct HTMLRenderer {
    public static func render(_ view: Renderable) -> String {
        let body = view.layout().lines().map { StyleExpander.html($0) }.joined(separator: "\n")
        return "<html><body><pre>\n" + body + "\n</pre></body></html>"
    }
}
