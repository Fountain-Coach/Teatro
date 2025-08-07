import Foundation

/// Shared helpers for expanding `TextSpan` style information.
public enum StyleExpander {
    public static func expand(_ spans: [TextSpan], using mapper: (TextStyle, String) -> String) -> String {
        spans.map { mapper($0.style, $0.text) }.joined()
    }

    public static func markdown(_ spans: [TextSpan]) -> String {
        expand(spans) { style, text in
            switch style {
            case .bold:
                return "**\(text)**"
            case .italic:
                return "*\(text)*"
            case .underline:
                return "_\(text)_"
            case .plain:
                return text
            }
        }
    }

    public static func html(_ spans: [TextSpan]) -> String {
        expand(spans) { style, text in
            switch style {
            case .bold:
                return "<strong>\(text)</strong>"
            case .italic:
                return "<em>\(text)</em>"
            case .underline:
                return "<u>\(text)</u>"
            case .plain:
                return text
            }
        }
    }

    public static func svg(_ spans: [TextSpan]) -> String {
        expand(spans) { style, text in
            switch style {
            case .bold:
                return "<tspan font-weight=\"bold\">\(text)</tspan>"
            case .italic:
                return "<tspan font-style=\"italic\">\(text)</tspan>"
            case .underline:
                return "<tspan text-decoration=\"underline\">\(text)</tspan>"
            case .plain:
                return text
            }
        }
    }
}

