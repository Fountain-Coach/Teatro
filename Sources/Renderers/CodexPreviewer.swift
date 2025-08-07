public struct CodexPreviewer: RendererPlugin {
    public static let identifier = "codex"
    public static let fileExtensions: [String] = []

    public static func preview(_ view: Renderable) -> String {
        """
        /// Codex Preview:
        ///
        /// Source:
        /// \(String(describing: type(of: view)))
        ///
        /// Output:
        \(view.layout().toText())
        """
    }

    public static func render(view: Renderable, output: String?) throws {
        let result = preview(view)
        try write(result, to: output, defaultName: "output.codex")
    }
}
