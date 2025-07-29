import Foundation

public struct SVGRenderer {
    // Default canvas width in points. Override with `TEATRO_SVG_WIDTH`.
    private static var canvasWidth: Int {
        Int(ProcessInfo.processInfo.environment["TEATRO_SVG_WIDTH"] ?? "600") ?? 600
    }

    // Default canvas height in points. Override with `TEATRO_SVG_HEIGHT`.
    private static var canvasHeight: Int {
        Int(ProcessInfo.processInfo.environment["TEATRO_SVG_HEIGHT"] ?? "400") ?? 400
    }

    nonisolated(unsafe) private static var cache: [String: String] = [:]

    public static func render(_ view: Renderable) -> String {
        let key = view.render()
        if let cached = cache[key] { return cached }

        var y = 20
        let rendered = view.render().components(separatedBy: "\n").map { line -> String in
            defer { y += 20 }
            let styled = applyStyle(line)
            return "<text x=\"10\" y=\"\(y)\" font-family=\"monospace\" font-size=\"14\">\(styled)</text>"
        }.joined(separator: "\n")

        let svg = """
        <svg xmlns=\"http://www.w3.org/2000/svg\" width=\"\(canvasWidth)\" height=\"\(max(canvasHeight, y))\">
        \(rendered)
        </svg>
        """

        cache[key] = svg
        return svg
    }

    private static func applyStyle(_ line: String) -> String {
        var result = line
        result = result.replacing("\\*\\*(.+?)\\*\\*", with: "<tspan font-weight=\"bold\">$1</tspan>")
        result = result.replacing("\\*(.+?)\\*", with: "<tspan font-style=\"italic\">$1</tspan>")
        result = result.replacing("_(.+?)_", with: "<tspan text-decoration=\"underline\">$1</tspan>")
        return result
    }
}

private extension String {
    func replacing(_ pattern: String, with template: String) -> String {
        replacingOccurrences(of: pattern, with: template, options: .regularExpression)
    }
}
