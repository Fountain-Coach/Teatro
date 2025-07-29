import Foundation

public protocol Renderable {
    func render() -> String
}

public protocol Layouting: Renderable {
    var alignment: Alignment { get }
    var padding: Int { get }
}

public enum Alignment: String {
    case leading = "left"
    case center = "center"
    case trailing = "right"
}

public enum TextStyle {
    case bold, italic, underline, plain

    public func apply(to content: String) -> String {
        switch self {
        case .bold: return "**\(content)**"
        case .italic: return "*\(content)*"
        case .underline: return "_\(content)_"
        case .plain: return content
        }
    }
}

@resultBuilder
public enum ViewBuilder {
    public static func buildBlock(_ components: Renderable...) -> [Renderable] {
        components
    }

    public static func buildExpression(_ expression: Renderable) -> Renderable {
        expression
    }
}
