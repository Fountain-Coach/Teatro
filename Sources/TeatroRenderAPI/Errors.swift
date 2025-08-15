import Foundation

public enum RenderError: Error, CustomStringConvertible {
    case parse(String)
    case layout(String)
    case io(String)
    case unsupported(String)

    public var description: String {
        switch self {
        case .parse(let m): return "Parse error: \(m)"
        case .layout(let m): return "Layout error: \(m)"
        case .io(let m): return "I/O error: \(m)"
        case .unsupported(let m): return "Unsupported: \(m)"
        }
    }
}
