public struct HTMLRenderer {
    public static func render(_ view: Renderable) -> String {
        "<html><body><pre>\n" + view.layout().toText() + "\n</pre></body></html>"
    }
}
