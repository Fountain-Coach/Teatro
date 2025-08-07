import Foundation

/// Represents a parsing error with location and context information.
public struct ParserError: Error, CustomStringConvertible {
    /// Human-readable message describing the error.
    public let message: String
    /// Byte offset of the error in the source text.
    public let offset: Int
    /// Line number (1-based) where the error occurred.
    public let line: Int
    /// Column number (1-based) where the error occurred.
    public let column: Int
    /// Snippet of the source surrounding the error with a caret indicator.
    public let snippet: String

    public var description: String {
        "\(message) at line \(line), column \(column)\n\(snippet)"
    }

    /// Creates a new parser error given a message, source text, and error index.
    /// - Parameters:
    ///   - message: Description of the failure.
    ///   - text: Full source text being parsed.
    ///   - index: Index within `text` where the error occurred.
    public init(message: String, text: String, index: String.Index) {
        self.message = message
        self.offset = text.distance(from: text.startIndex, to: index)
        var lineNumber = 1
        var columnNumber = 1
        var lineStart = text.startIndex
        var i = text.startIndex
        while i < index {
            if text[i] == "\n" {
                lineNumber += 1
                columnNumber = 1
                lineStart = text.index(after: i)
            } else {
                columnNumber += 1
            }
            i = text.index(after: i)
        }
        self.line = lineNumber
        self.column = columnNumber
        let lineEnd = text[lineStart...].firstIndex(of: "\n") ?? text.endIndex
        let lineText = String(text[lineStart..<lineEnd])
        let caret = String(repeating: " ", count: columnNumber - 1) + "^"
        self.snippet = lineText + "\n" + caret
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
