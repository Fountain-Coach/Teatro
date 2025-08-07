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
    public static func parse(_ text: String) throws -> Storyboard {
        var steps: [StoryboardStep] = []
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false)
        var offset = 0
        var index = 0
        while index < lines.count {
            let rawLine = lines[index]
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            defer { offset += rawLine.count + 1; index += 1 }
            if line.isEmpty { continue }
            if line.lowercased().hasPrefix("scene:") {
                let name = line.dropFirst("scene:".count).trimmingCharacters(in: .whitespaces)
                var content = ""
                if index + 1 < lines.count {
                    let nextRaw = lines[index + 1]
                    let next = nextRaw.trimmingCharacters(in: .whitespaces)
                    if next.lowercased().hasPrefix("text:") {
                        content = next.dropFirst("text:".count).trimmingCharacters(in: .whitespaces)
                        index += 1
                        offset += nextRaw.count + 1
                    }
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
            } else {
                let idx = text.index(text.startIndex, offsetBy: offset)
                throw ParserError(message: "Unexpected line", text: text, index: idx)
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
