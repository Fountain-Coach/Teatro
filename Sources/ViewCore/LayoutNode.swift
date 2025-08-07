import Foundation

public indirect enum LayoutNode {
    case text(String, style: TextStyle)
    case hStack(alignment: Alignment, spacing: Int, distribution: Distribution, padding: Int, children: [LayoutNode])
    case vStack(alignment: Alignment, spacing: Int, distribution: Distribution, padding: Int, children: [LayoutNode])
    case zStack(children: [LayoutNode])
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
        case .hStack(_, let spacing, let distribution, let padding, let children):
            let indent = TextSpan(text: String(repeating: " ", count: padding), style: .plain)
            var line: [TextSpan] = [indent]
            let leadingSpaces = distribution == .trailing ? spacing : (distribution == .center ? spacing / 2 : 0)
            let trailingSpaces = distribution == .center ? spacing / 2 : 0
            if leadingSpaces > 0 {
                line.append(TextSpan(text: String(repeating: " ", count: leadingSpaces), style: .plain))
            }
            for (i, child) in children.enumerated() {
                if i > 0 {
                    line.append(TextSpan(text: String(repeating: " ", count: spacing), style: .plain))
                }
                let childLine = child.lines().first ?? []
                line.append(contentsOf: childLine)
            }
            if trailingSpaces > 0 {
                line.append(TextSpan(text: String(repeating: " ", count: trailingSpaces), style: .plain))
            }
            return [line]
        case .vStack(_, let spacing, let distribution, let padding, let children):
            let indent = TextSpan(text: String(repeating: " ", count: padding), style: .plain)
            var result: [[TextSpan]] = []
            let topSpacing = distribution == .trailing ? spacing : (distribution == .center ? spacing : 0)
            let bottomSpacing = distribution == .center ? spacing : 0
            if topSpacing > 0 {
                result.append(contentsOf: Array(repeating: [indent], count: topSpacing))
            }
            for (i, child) in children.enumerated() {
                for line in child.lines() {
                    result.append([indent] + line)
                }
                if i < children.count - 1 && spacing > 0 {
                    result.append(contentsOf: Array(repeating: [indent], count: spacing))
                }
            }
            if bottomSpacing > 0 {
                result.append(contentsOf: Array(repeating: [indent], count: bottomSpacing))
            }
            return result
        case .zStack(let children):
            let childStrings = children.map { $0.toText().components(separatedBy: "\n") }
            let maxLines = childStrings.map { $0.count }.max() ?? 0
            var resultLines: [String] = Array(repeating: "", count: maxLines)
            func overlay(_ base: String, _ top: String) -> String {
                let width = max(base.count, top.count)
                var chars = Array(repeating: Character(" "), count: width)
                let baseChars = Array(base)
                let topChars = Array(top)
                for i in 0..<baseChars.count { chars[i] = baseChars[i] }
                for i in 0..<topChars.count { if topChars[i] != " " { chars[i] = topChars[i] } }
                return String(chars)
            }
            for lines in childStrings {
                for i in 0..<maxLines {
                    let topLine = i < lines.count ? lines[i] : ""
                    resultLines[i] = overlay(resultLines[i], topLine)
                }
            }
            return resultLines.map { [TextSpan(text: $0, style: .plain)] }
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
