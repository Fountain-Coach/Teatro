public struct HTMLRenderer {
    public static func render(_ view: Renderable) -> String {
        "<html><body><pre>\n" + view.render() + "\n</pre></body></html>"
    }
}
