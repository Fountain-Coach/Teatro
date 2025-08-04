import Foundation

/// Parser for Csound .csd files.
public enum CSDParserError: Error {
    case missingOrchestra
    case missingScore
}

public struct CSDParser {
    /// Parses a Csound CSD document into a `CsoundScore`.
    /// - Parameter text: Full text of the .csd file.
    /// - Returns: A `CsoundScore` containing orchestra and score sections.
    public static func parse(_ text: String) throws -> CsoundScore {
        guard let orchestra = extract(tag: "Orchestra", from: text) else {
            throw CSDParserError.missingOrchestra
        }
        guard let score = extract(tag: "Score", from: text) else {
            throw CSDParserError.missingScore
        }
        return CsoundScore(orchestra: orchestra, score: score)
    }

    /// Extracts the contents of an XML-like tag from the input text.
    private static func extract(tag: String, from text: String) -> String? {
        let startTag = "<\(tag)>"
        let endTag = "</\(tag)>"
        guard let startRange = text.range(of: startTag),
              let endRange = text.range(of: endTag, range: startRange.upperBound..<text.endIndex) else {
            return nil
        }
        let content = text[startRange.upperBound..<endRange.lowerBound]
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
