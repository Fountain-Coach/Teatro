public struct CodexStoryboardPreviewer {
    public static func prompt(_ storyboard: Storyboard) -> String {
        let frames = storyboard.frames()
        let rendered = frames.enumerated().map { idx, frame in
            "Frame \(idx):\n" + frame.render()
        }.joined(separator: "\n\n")
        return """
        /// Codex Storyboard Preview
        ///
        /// Frames: \(frames.count)
        \(rendered)
        """
    }
}
