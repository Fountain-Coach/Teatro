import Foundation

public enum RenderError: Error, CustomStringConvertible {
    case parse(String)
    case layout(String)
    case ioError(String)
    case unsupported(String)

    public var description: String {
        switch self {
        case .parse(let message): return "Parse error: \(message)"
        case .layout(let message): return "Layout error: \(message)"
        case .ioError(let message): return "I/O error: \(message)"
        case .unsupported(let message): return "Unsupported: \(message)"
        }
    }
}
