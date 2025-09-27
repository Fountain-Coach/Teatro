import Foundation

public enum OrchestrationTrigger: Equatable {
    case toolCall(endpoint: String)
    case sse(filename: String)
    case reflect
    case promote(role: String)
    case summary
}

public enum InjectedBlock: Equatable {
    case toolResponse(String)
    case reflectionReply(String)
    case sseChunk(String)
    case promotionConfirmation(String)
    case summaryBlock(String)
}

extension FountainParser {
    // MARK: - FountainAI Rule Helpers
    func isCorpusHeader(_ line: String) -> Bool {
        line.trimmingCharacters(in: .whitespaces).lowercased().hasPrefix("#corpus:")
    }

    func isBaseline(_ line: String) -> Bool {
        line.trimmingCharacters(in: .whitespaces).lowercased().hasPrefix("> baseline:")
    }

    func isSSE(_ line: String) -> Bool {
        line.trimmingCharacters(in: .whitespaces).lowercased().hasPrefix("> sse:")
    }

    func isToolCall(_ line: String) -> Bool {
        line.trimmingCharacters(in: .whitespaces).lowercased().hasPrefix("> tool_call:")
    }

    func isReflect(_ line: String) -> Bool {
        line.trimmingCharacters(in: .whitespaces).uppercased().hasPrefix("REFLECT:")
    }

    func isPromote(_ line: String) -> Bool {
        line.trimmingCharacters(in: .whitespaces).uppercased().hasPrefix("PROMOTE:")
    }

    func isSummary(_ line: String) -> Bool {
        line.trimmingCharacters(in: .whitespaces).uppercased().hasPrefix("SUMMARY:")
    }
}
