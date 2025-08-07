import Foundation

public indirect enum LayoutNode {
    case text(String, style: TextStyle)
    case hStack(alignment: Alignment, padding: Int, children: [LayoutNode])
    case vStack(alignment: Alignment, padding: Int, children: [LayoutNode])
    case panel(width: Int, height: Int, cornerRadius: Int, children: [LayoutNode])
    case stage(title: String, child: LayoutNode)
    case raw(String)
}

public struct TextSpan {
    public let text: String
    public let style: TextStyle
}

public extension LayoutNode {
    func lines() -> [[TextSpan]] {
        switch self {
        case .text(let content, let style):
            return [[TextSpan(text: content, style: style)]]
        case .raw(let str):
            return str.components(separatedBy: "\n").map { [TextSpan(text: $0, style: .plain)] }
        case .hStack(_, let padding, let children):
            let indent = TextSpan(text: String(repeating: " ", count: padding), style: .plain)
            var line: [TextSpan] = [indent]
            for (i, child) in children.enumerated() {
                if i > 0 { line.append(TextSpan(text: " ", style: .plain)) }
                let childLine = child.lines().first ?? []
                line.append(contentsOf: childLine)
            }
            return [line]
        case .vStack(_, let padding, let children):
            let indent = TextSpan(text: String(repeating: " ", count: padding), style: .plain)
            var result: [[TextSpan]] = []
            for child in children {
                for line in child.lines() {
                    result.append([indent] + line)
                }
            }
            return result
        case .panel(let width, let height, let cornerRadius, let children):
            var result: [[TextSpan]] = [[TextSpan(text: "[Panel \(width)x\(height) r:\(cornerRadius)]", style: .plain)]]
            for child in children {
                result.append(contentsOf: child.lines())
            }
            return result
        case .stage(let title, let child):
            var result: [[TextSpan]] = [[TextSpan(text: "[Stage: \(title)]", style: .plain)]]
            result.append(contentsOf: child.lines())
            return result
        }
    }

    func toText() -> String {
        lines().map { line in
            line.map { $0.style.apply(to: $0.text) }.joined()
        }.joined(separator: "\n")
    }

    static func legacy(_ text: String) -> LayoutNode {
        .raw(text)
    }
}

public struct LegacyText: Renderable {
    public let text: String
    public init(_ text: String) { self.text = text }
    public func layout() -> LayoutNode { .raw(text) }
}
