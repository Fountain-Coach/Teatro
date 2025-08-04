import Foundation

/// Simple parser for `.session` files.
/// Currently treats the session file as plain text and wraps it into a `Session` renderable.
public struct SessionParser {
    /// Parses the session text into a `Session`.
    /// - Parameter text: Raw session text.
    /// - Returns: A `Session` renderable wrapping the text.
    public static func parse(_ text: String) -> Session {
        Session(text: text)
    }
}

/// Represents a session log or container for the CLI.
public struct Session: Renderable {
    /// Raw textual content of the session.
    public let text: String

    /// Creates a new session from raw text.
    public init(text: String) {
        self.text = text
    }

    /// Renders the session as plain text.
    public func render() -> String {
        text
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
