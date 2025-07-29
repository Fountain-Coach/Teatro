public struct CodexPreviewer {
    public static func preview(_ view: Renderable) -> String {
        """
        /// Codex Preview:
        ///
        /// Source:
        /// \(String(describing: type(of: view)))
        ///
        /// Output:
        \(view.render())
        """
    }
}
