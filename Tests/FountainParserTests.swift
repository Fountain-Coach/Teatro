import XCTest
@testable import Teatro

final class FountainParserTests: XCTestCase {
    func testParsesSceneHeadingAndCharacter() {
        let text = """
TITLE: Example

INT. HOUSE - DAY

JOHN
Hello.
"""
        let parser = FountainParser()
        let nodes = parser.parse(text)
        XCTAssertEqual(nodes.first?.type, .titlePageField(key: "TITLE"))
        XCTAssertTrue(nodes.contains { $0.type == .sceneHeading })
        XCTAssertTrue(nodes.contains { $0.type == .character })
        XCTAssertTrue(nodes.contains { $0.type == .dialogue })
    }

    func testParsesNote() {
        let parser = FountainParser()
        let nodes = parser.parse("[[note]]")
        XCTAssertEqual(nodes.first?.type, .note)
    }

    func testMultiLineNoteAndBoneyard() {
        let text = """
[[note
line]]
/* bone
yard */
"""
        let parser = FountainParser()
        let nodes = parser.parse(text)
        XCTAssertTrue(nodes.contains { $0.type == .note && $0.rawText.contains("line") })
        XCTAssertTrue(nodes.contains { $0.type == .boneyard && $0.rawText.contains("bone") })
    }

    func testEmphasisParsing() {
        let parser = FountainParser()
        let nodes = parser.parse("JOHN\nI *love* **Swift** _very_ much")
        let dialogue = nodes.first { $0.type == .dialogue }
        XCTAssertNotNil(dialogue)
        XCTAssertTrue(dialogue!.children.contains { $0.type == .emphasis(style: .italic) })
        XCTAssertTrue(dialogue!.children.contains { $0.type == .emphasis(style: .bold) })
        XCTAssertTrue(dialogue!.children.contains { $0.type == .emphasis(style: .underline) })
    }

    func testForcedActionAndTransition() {
        let text = """
!INT. WRONG
> CUT TO:
"""
        let parser = FountainParser()
        let nodes = parser.parse(text)
        XCTAssertTrue(nodes.contains { $0.type == .action && $0.rawText.contains("INT.") })
        XCTAssertTrue(nodes.contains { $0.type == .transition })
    }

    func testMultiLineTitleField() {
        let text = """
TITLE: Test
  Another
"""
        let nodes = FountainParser().parse(text)
        XCTAssertEqual(nodes.first?.type, .titlePageField(key: "TITLE"))
        XCTAssertTrue(nodes.first?.rawText.contains("Another") ?? false)
    }

    func testDualDialogue() {
        let script = """
JOE^
Hello
BOB^
Hi
"""
        let nodes = FountainParser().parse(script)
        XCTAssertTrue(nodes.contains { $0.type == .dualDialogue })
    }

    func testSectionsSynopsisCenteredAndPageBreak() {
        let script = """
# Opening
= A summary
> TITLE <
===
"""
        let nodes = FountainParser().parse(script)
        XCTAssertTrue(nodes.contains { if case .section(level: 1) = $0.type { return true } else { return false } })
        XCTAssertTrue(nodes.contains { $0.type == .synopsis })
        XCTAssertTrue(nodes.contains { $0.type == .centered })
        XCTAssertTrue(nodes.contains { $0.type == .pageBreak })
    }

    func testCustomRuleSet() {
        let rules = RuleSet(sceneHeadingKeywords: ["INT.", "EXT.", "LOC."], enableNotes: false)
        let script = """
[[note]]
LOC. MARKET - DAY
"""
        let nodes = FountainParser(rules: rules).parse(script)
        XCTAssertEqual(nodes.first?.type, .action)
        XCTAssertTrue(nodes.contains { $0.type == .sceneHeading && $0.rawText.contains("LOC.") })
    }

    func testEndToEndExampleScript() {
        let script = """
INT. LAB - NIGHT

The robot assembles a memory core.

ROBOT
(to itself)
I was not made for silence.

CUT TO:

EXT. CITY STREET - NIGHT
"""
        let nodes = FountainParser().parse(script)
        let types = nodes.map { $0.type }
        let expected: [FountainElementType] = [
            .sceneHeading,
            .action,
            .character,
            .parenthetical,
            .dialogue,
            .transition,
            .sceneHeading
        ]
        XCTAssertEqual(types, expected)
    }

    func testFountainAIRules() {
        let script = """
        #corpus: test-corpus
        > BASELINE: data
        > SSE: event
        > tool_call: /path
        REFLECT: note
        PROMOTE: role
        SUMMARY: done
        """
        let nodes = FountainParser().parse(script)
        XCTAssertTrue(nodes.contains { $0.type == .corpusHeader })
        XCTAssertTrue(nodes.contains { $0.type == .baseline })
        XCTAssertTrue(nodes.contains { $0.type == .sse })
        XCTAssertTrue(nodes.contains { $0.type == .toolCall })
        XCTAssertTrue(nodes.contains { $0.type == .reflect })
        XCTAssertTrue(nodes.contains { $0.type == .promote })
        XCTAssertTrue(nodes.contains { $0.type == .summary })
    }
}

