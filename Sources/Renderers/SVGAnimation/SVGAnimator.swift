import Foundation

public struct SVGAnimator {
    public static func diff(from: Renderable, to: Renderable) -> [SVGDelta] {
        // 🧪 Placeholder: for now, return empty
        return []
    }

    /// Renders a storyboard as an animated SVG document.
    ///
    /// Each scene becomes a `<g>` element with animated opacity so that
    /// subsequent scenes fade in and out on a global timeline. The `begin`
    /// attribute is used to stagger the animations according to the frame
    /// index. Every frame lasts for one second.
    public static func renderAnimatedSVG(
        storyboard: Storyboard,
        fadeInDuration: Double = 1.0,
        fadeOutDuration: Double = 0.5
    ) -> String {
        let frames = storyboard.frames()
        var groups: [String] = []

        for (i, frame) in frames.enumerated() {
            let id = "scene\(i)"
            let lines = frame.render().components(separatedBy: "\n")

            let content = lines.enumerated().map { j, line in
                "<text x=\"10\" y=\"\(20 + j * 20)\" font-family=\"monospace\" font-size=\"14\">\(line)</text>"
            }.joined(separator: "\n")

            let fadeIn = SVGAnimate(
                attributeName: "opacity",
                from: "0", to: "1", dur: fadeInDuration, repeatCount: nil
            ).render().replacingOccurrences(of: ">", with: " begin=\"\(i)s\">", options: .literal)

            let fadeOut = SVGAnimate(
                attributeName: "opacity",
                from: "1", to: "0", dur: fadeOutDuration, repeatCount: nil
            ).render().replacingOccurrences(of: ">", with: " begin=\"\(i + 1)s\">", options: .literal)

            let group = """
            <g id=\"\(id)\" opacity=\"0\">
            \(content)
            \(fadeIn)
            \(fadeOut)
            </g>
            """

            groups.append(group)
        }

        let svgBody = groups.joined(separator: "\n")

        return """
        <svg xmlns=\"http://www.w3.org/2000/svg\" width=\"600\" height=\"\(20 + frames.count * 20)\">
        \(svgBody)
        </svg>
        """
    }
}
