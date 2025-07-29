import Foundation

public struct RuleSet: Sendable {
    public var sceneHeadingKeywords: [String]
    public var transitionKeywords: [String]
    public var enableNotes: Bool
    public var enableBoneyard: Bool
    public var enableSections: Bool
    public var enableSynopses: Bool

    public init(sceneHeadingKeywords: [String] = ["INT.", "EXT.", "INT/EXT.", "I/E."],
                transitionKeywords: [String] = ["TO:"],
                enableNotes: Bool = true,
                enableBoneyard: Bool = true,
                enableSections: Bool = true,
                enableSynopses: Bool = true) {
        self.sceneHeadingKeywords = sceneHeadingKeywords
        self.transitionKeywords = transitionKeywords
        self.enableNotes = enableNotes
        self.enableBoneyard = enableBoneyard
        self.enableSections = enableSections
        self.enableSynopses = enableSynopses
    }

    public static let `default` = RuleSet()
}

public enum EmphasisStyle: Equatable {
    case italic
    case bold
    case underline
    case boldItalic
}

public enum FountainElementType: Equatable {
    case sceneHeading
    case action
    case character
    case parenthetical
    case dialogue
    case dualDialogue
    case lyrics
    case transition
    case centered
    case pageBreak
    case section(level: Int)
    case synopsis
    case note
    case boneyard
    case titlePageField(key: String)
    case text
    case emphasis(style: EmphasisStyle)
    // FountainAI extensions
    case corpusHeader
    case baseline
    case sse
    case toolCall
    case reflect
    case promote
    case summary
}

public struct FountainNode: Equatable {
    public var type: FountainElementType
    public var rawText: String
    public var lineNumber: Int
    public var children: [FountainNode] = []

    public init(type: FountainElementType, rawText: String, lineNumber: Int, children: [FountainNode] = []) {
        self.type = type
        self.rawText = rawText
        self.lineNumber = lineNumber
        self.children = children
    }
}

public final class FountainParser {
    enum State { case titlePage, body, note, boneyard }

    private let rules: RuleSet

    public init(rules: RuleSet = .default) {
        self.rules = rules
    }

    public func parse(_ text: String) -> [FountainNode] {
        var elements: [FountainNode] = []
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false)
        var state: State = .titlePage
        var lineNumber = 1
        var currentNote: String = ""
        var currentBoneyard: String = ""
        var previousBlank = true
        var lastTitleIndex: Int? = nil
        var lastElement: FountainElementType? = nil
        for (idx, raw) in lines.enumerated() {
            let line = String(raw)
            let nextLine = idx + 1 < lines.count ? String(lines[idx + 1]) : ""
            let nextBlank = nextLine.trimmingCharacters(in: .whitespaces).isEmpty
            switch state {
            case .titlePage:
                if let field = parseTitlePage(line) {
                    let node = FountainNode(type: .titlePageField(key: field.key), rawText: field.raw, lineNumber: lineNumber)
                    elements.append(node)
                    lastTitleIndex = elements.count - 1
                } else if line.first == " " || line.first == "\t", let idx = lastTitleIndex {
                    elements[idx].rawText += "\n" + line.trimmingCharacters(in: .whitespaces)
                } else if line.trimmingCharacters(in: .whitespaces).isEmpty {
                    state = .body
                } else {
                    state = .body
                    // handle line again under body rules
                    if rules.enableNotes, line.trimmingCharacters(in: .whitespaces).hasPrefix("[[") {
                        let trimmed = line.trimmingCharacters(in: .whitespaces)
                        if trimmed.hasSuffix("]]") {
                            let content = trimmed.dropFirst(2).dropLast(2)
                            elements.append(FountainNode(type: .note, rawText: String(content), lineNumber: lineNumber))
                        } else {
                            state = .note
                            currentNote = String(trimmed.dropFirst(2))
                        }
                    } else if rules.enableBoneyard, line.trimmingCharacters(in: .whitespaces).hasPrefix("/*") {
                        let trimmed = line.trimmingCharacters(in: .whitespaces)
                        if trimmed.hasSuffix("*/") {
                            let content = trimmed.dropFirst(2).dropLast(2)
                            elements.append(FountainNode(type: .boneyard, rawText: String(content), lineNumber: lineNumber))
                        } else {
                            state = .boneyard
                            currentBoneyard = String(trimmed.dropFirst(2))
                        }
                    } else if let element = parseBody(line: line, previousBlank: previousBlank, nextBlank: nextBlank, lastElement: lastElement) {
                        let inline = parseInline(line)
                        elements.append(FountainNode(type: element, rawText: line, lineNumber: lineNumber, children: inline))
                        lastElement = element
                    } else {
                        lastElement = nil
                    }
                }
            case .body:
                if rules.enableNotes, line.trimmingCharacters(in: .whitespaces).hasPrefix("[[") {
                    let trimmed = line.trimmingCharacters(in: .whitespaces)
                    if trimmed.hasSuffix("]]") {
                        let content = trimmed.dropFirst(2).dropLast(2)
                        elements.append(FountainNode(type: .note, rawText: String(content), lineNumber: lineNumber))
                    } else {
                        state = .note
                        currentNote = String(trimmed.dropFirst(2))
                    }
                } else if rules.enableBoneyard, line.trimmingCharacters(in: .whitespaces).hasPrefix("/*") {
                    let trimmed = line.trimmingCharacters(in: .whitespaces)
                    if trimmed.hasSuffix("*/") {
                        let content = trimmed.dropFirst(2).dropLast(2)
                        elements.append(FountainNode(type: .boneyard, rawText: String(content), lineNumber: lineNumber))
                    } else {
                        state = .boneyard
                        currentBoneyard = String(trimmed.dropFirst(2))
                    }
                } else if let element = parseBody(line: line, previousBlank: previousBlank, nextBlank: nextBlank, lastElement: lastElement) {
                    let inline = parseInline(line)
                    elements.append(FountainNode(type: element, rawText: line, lineNumber: lineNumber, children: inline))
                    lastElement = element
                } else {
                    lastElement = nil
                }
            case .note:
                let trimmedNote = line.trimmingCharacters(in: .whitespaces)
                if trimmedNote.isEmpty {
                    elements.append(FountainNode(type: .note, rawText: currentNote, lineNumber: lineNumber))
                    currentNote = ""
                    state = .body
                } else if trimmedNote.hasSuffix("]]") {
                    currentNote += "\n" + String(trimmedNote.dropLast(2))
                    elements.append(FountainNode(type: .note, rawText: currentNote, lineNumber: lineNumber))
                    currentNote = ""
                    state = .body
                } else {
                    currentNote += "\n" + line
                }
            case .boneyard:
                if line.trimmingCharacters(in: .whitespaces).hasSuffix("*/") {
                    currentBoneyard += "\n" + String(line.dropLast(2))
                    elements.append(FountainNode(type: .boneyard, rawText: currentBoneyard, lineNumber: lineNumber))
                    currentBoneyard = ""
                    state = .body
                } else {
                    currentBoneyard += "\n" + line
                }
            }
            previousBlank = line.trimmingCharacters(in: .whitespaces).isEmpty
            if previousBlank { lastElement = nil }
            lineNumber += 1
        }
        if state == .note {
            elements.append(FountainNode(type: .note, rawText: currentNote, lineNumber: lineNumber))
        } else if state == .boneyard {
            elements.append(FountainNode(type: .boneyard, rawText: currentBoneyard, lineNumber: lineNumber))
        }
        return elements
    }

    private func parseTitlePage(_ line: String) -> (key: String, raw: String)? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard let colonIndex = trimmed.firstIndex(of: ":") else { return nil }
        let key = String(trimmed[..<colonIndex])
        let value = trimmed[colonIndex...]
        guard !key.isEmpty && key.uppercased() == key else { return nil }
        return (key: key, raw: String(value.dropFirst()).trimmingCharacters(in: .whitespaces))
    }

    private func parseBody(line: String, previousBlank: Bool, nextBlank: Bool, lastElement: FountainElementType?) -> FountainElementType? {
        var trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { return nil }

        // FountainAI overrides
        if isCorpusHeader(trimmed) { return .corpusHeader }
        if isBaseline(trimmed) { return .baseline }
        if isSSE(trimmed) { return .sse }
        if isToolCall(trimmed) { return .toolCall }
        if isReflect(trimmed) { return .reflect }
        if isPromote(trimmed) { return .promote }
        if isSummary(trimmed) { return .summary }

        if isAction(trimmed) { return .action }

        if trimmed.hasPrefix(">") {
            var checkRaw = line
            if let first = checkRaw.first, first == ">" { checkRaw.removeFirst() }
            var check = trimmed
            check.removeFirst()
            if isTransition(checkRaw, trimmed: check, previousBlank: true, nextBlank: nextBlank) { return .transition }
        }

        if isPageBreak(trimmed) { return .pageBreak }
        if let level = sectionLevel(trimmed) { return .section(level: level) }
        if isSynopsis(trimmed) { return .synopsis }
        if isSceneHeading(trimmed) { return .sceneHeading }
        if isTransition(line, trimmed: trimmed, previousBlank: previousBlank, nextBlank: nextBlank) { return .transition }
        if isLyrics(trimmed) { return .lyrics }
        if isCentered(trimmed) { return .centered }
        if isDualDialogue(trimmed, previousBlank: previousBlank) { return .dualDialogue }
        if isCharacter(trimmed, previousBlank: previousBlank) { return .character }
        if isParenthetical(trimmed, last: lastElement) { return .parenthetical }
        if isDialogue(trimmed, last: lastElement) { return .dialogue }
        return .action
    }

    private func isSceneHeading(_ line: String) -> Bool {
        for keyword in rules.sceneHeadingKeywords {
            if line.uppercased().hasPrefix(keyword.uppercased()) { return true }
        }
        return line.hasPrefix(".")
    }

    private func isTransition(_ raw: String, trimmed: String, previousBlank: Bool, nextBlank: Bool) -> Bool {
        guard previousBlank && nextBlank else { return false }
        if trimmed.hasSuffix(":") && raw.hasSuffix(": ") { return false }
        guard isAllCaps(trimmed) else { return false }
        for keyword in rules.transitionKeywords {
            if trimmed.hasSuffix(keyword.uppercased()) { return true }
        }
        return false
    }

    private func isPageBreak(_ line: String) -> Bool {
        line.trimmingCharacters(in: .whitespaces).allSatisfy { $0 == "=" } && line.count >= 3
    }

    private func isCentered(_ line: String) -> Bool {
        line.hasPrefix(">") && line.hasSuffix("<")
    }

    private func isAllCaps(_ line: String) -> Bool {
        let letters = line.trimmingCharacters(in: .whitespaces)
        guard !letters.isEmpty else { return false }
        return letters == letters.uppercased()
    }

    // MARK: - Detection Helpers

    private func isAction(_ line: String) -> Bool {
        line.hasPrefix("!")
    }

    private func isCharacter(_ line: String, previousBlank: Bool) -> Bool {
        guard previousBlank else { return false }
        var text = line
        if text.hasSuffix("^") { text.removeLast() }
        return isAllCaps(text)
    }

    private func isParenthetical(_ line: String, last: FountainElementType?) -> Bool {
        guard line.hasPrefix("(") else { return false }
        if let last = last {
            switch last {
            case .character, .dialogue, .dualDialogue, .parenthetical:
                return true
            default:
                return false
            }
        }
        return false
    }

    private func isDualDialogue(_ line: String, previousBlank: Bool) -> Bool {
        return isAllCaps(line) && line.hasSuffix("^")
    }

    private func isLyrics(_ line: String) -> Bool {
        line.hasPrefix("~")
    }

    private func sectionLevel(_ line: String) -> Int? {
        guard rules.enableSections else { return nil }
        guard line.hasPrefix("#") else { return nil }
        return line.prefix { $0 == "#" }.count
    }

    private func isSynopsis(_ line: String) -> Bool {
        guard rules.enableSynopses else { return false }
        return line.hasPrefix("=") && !isPageBreak(line)
    }

    private func isDialogue(_ line: String, last: FountainElementType?) -> Bool {
        guard let last = last else { return false }
        switch last {
        case .character, .parenthetical, .dualDialogue, .dialogue:
            return true
        default:
            return false
        }
    }

    private func parseInline(_ text: String) -> [FountainNode] {
        var result: [FountainNode] = []
        var index = text.startIndex
        var buffer = ""

        func flush() {
            if !buffer.isEmpty {
                result.append(FountainNode(type: .text, rawText: buffer, lineNumber: 0))
                buffer.removeAll()
            }
        }

        while index < text.endIndex {
            let char = text[index]
            if char == "\\" {
                let next = text.index(after: index)
                if next < text.endIndex {
                    buffer.append(text[next])
                    index = text.index(after: next)
                } else {
                    index = next
                }
                continue
            }

            if char == "*" || char == "_" {
                let markerChar = char
                var count = 1
                var endIdx = text.index(after: index)
                while markerChar == "*" && endIdx < text.endIndex && text[endIdx] == markerChar && count < 3 {
                    count += 1
                    endIdx = text.index(after: endIdx)
                }
                let marker = String(repeating: String(markerChar), count: count)
                var searchRange = endIdx..<text.endIndex
                var found: Range<String.Index>? = nil
                while let range = text.range(of: marker, range: searchRange) {
                    let prev = text.index(before: range.lowerBound)
                    if text[prev] != "\\" {
                        found = range
                        break
                    }
                    searchRange = text.index(after: range.lowerBound)..<text.endIndex
                }
                if let range = found {
                    flush()
                    let inner = String(text[endIdx..<range.lowerBound])
                    let children = parseInline(inner)
                    let style: EmphasisStyle
                    if markerChar == "_" {
                        style = .underline
                    } else if count == 1 {
                        style = .italic
                    } else if count == 2 {
                        style = .bold
                    } else {
                        style = .boldItalic
                    }
                    result.append(FountainNode(type: .emphasis(style: style), rawText: inner, lineNumber: 0, children: children))
                    index = range.upperBound
                    continue
                }
            }

            buffer.append(char)
            index = text.index(after: index)
        }

        flush()
        return result
    }
}
