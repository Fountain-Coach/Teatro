public enum FountainElement: Renderable {
    case sceneHeading(String)
    case characterCue(String)
    case dialogue(String)
    case action(String)
    case transition(String)

    public func layout() -> LayoutNode {
        switch self {
        case .sceneHeading(let txt): return .raw("# \(txt)")
        case .characterCue(let txt): return .raw("\n\(txt.uppercased())")
        case .dialogue(let txt): return .raw("\t\(txt)")
        case .action(let txt): return .raw(txt)
        case .transition(let txt): return .raw("\(txt) >>")
        }
    }
}

public struct FountainRenderer {
    public static func parse(_ text: String) -> [FountainElement] {
        let parser = FountainParser()
        let nodes = parser.parse(text)
        return nodes.compactMap { node in
            switch node.type {
            case .sceneHeading: return .sceneHeading(node.rawText)
            case .character: return .characterCue(node.rawText)
            case .dialogue, .dualDialogue: return .dialogue(node.rawText)
            case .transition: return .transition(node.rawText)
            case .action, .synopsis, .centered, .lyrics, .pageBreak, .section, .note, .boneyard, .titlePageField, .corpusHeader, .baseline, .sse, .toolCall, .reflect, .promote, .summary:
                return .action(node.rawText)
            case .parenthetical:
                return .dialogue(node.rawText)
            case .text, .emphasis:
                return nil
            }
        }
    }
}

public struct FountainSceneView: Renderable {
    public let elements: [FountainElement]

    public init(fountainText: String) {
        self.elements = FountainRenderer.parse(fountainText)
    }

    public func layout() -> LayoutNode {
        .raw(elements.map { $0.layout().toText() }.joined(separator: "\n"))
    }
}
