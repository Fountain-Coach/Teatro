import Foundation

/// Parser for simple Storyboard DSL files.
public struct StoryboardParser {
    /// Parses a storyboard script into a `Storyboard` instance.
    /// Format:
    ///
    /// Scene: Name
    /// Text: content line
    /// Transition: crossfade 1
    ///
    /// - Parameter text: The raw storyboard text.
    /// - Returns: Constructed `Storyboard`.
    public static func parse(_ text: String) -> Storyboard {
        var steps: [StoryboardStep] = []
        let lines = text.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespaces) }
        var index = 0
        while index < lines.count {
            let line = lines[index]
            if line.lowercased().hasPrefix("scene:") {
                let name = line.dropFirst("scene:".count).trimmingCharacters(in: .whitespaces)
                index += 1
                var content = ""
                if index < lines.count, lines[index].lowercased().hasPrefix("text:") {
                    content = lines[index].dropFirst("text:".count).trimmingCharacters(in: .whitespaces)
                    index += 1
                }
                let scene = Scene(name) { Text(content) }
                steps.append(.scene(scene))
            } else if line.lowercased().hasPrefix("transition:") {
                let rest = line.dropFirst("transition:".count).trimmingCharacters(in: .whitespaces)
                let parts = rest.split(separator: " ")
                let style: Transition.Style = parts.first?.lowercased() == "tween" ? .tween : .crossfade
                let frames = parts.count > 1 ? Int(parts[1]) ?? 1 : 1
                let transition = Transition(style: style, frames: frames)
                steps.append(.transition(transition))
                index += 1
            } else {
                index += 1
            }
        }
        return Storyboard(steps: steps)
    }
}

public extension Storyboard {
    /// Convenience initializer for constructing a storyboard from steps.
    init(steps: [StoryboardStep]) {
        self.steps = steps
    }
}

extension Storyboard: Renderable {
    public func layout() -> LayoutNode {
        .raw(CodexStoryboardPreviewer.prompt(self))
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
