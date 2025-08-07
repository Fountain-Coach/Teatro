import Foundation

/// Protocol for renderer plugins.
public protocol RendererPlugin {
    /// Primary identifier for the renderer (e.g. "html").
    static var identifier: String { get }
    /// Supported file extensions or aliases for this renderer.
    static var fileExtensions: [String] { get }
    /// Render the given view either to stdout or a file.
    /// - Parameters:
    ///   - view: View or score to render.
    ///   - output: Optional destination file path. If nil, output is printed.
    static func render(view: Renderable, output: String?) throws
}

public enum RendererError: Error {
    case unsupportedInput(String)
}

public extension RendererPlugin {
    static var fileExtensions: [String] { [] }

    /// Write a string either to stdout or to a file.
    static func write(_ string: String, to path: String?, defaultName: String) throws {
        if let path = path {
            try string.write(toFile: path, atomically: true, encoding: .utf8)
            print("Wrote \(path)")
        } else {
            print(string)
        }
    }

    /// Write raw data either to stdout (hex encoded) or to a file.
    static func writeData(_ data: Data, to path: String?, defaultName: String) throws {
        if let path = path {
            let url = URL(fileURLWithPath: path)
            try data.write(to: url)
            print("Wrote \(url.path)")
        } else {
            let hex = data.map { String(format: "%02X", $0) }.joined()
            print(hex)
        }
    }
}
