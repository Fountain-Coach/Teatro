import XCTest
import ArgumentParser
@testable import RenderCLI

func XCTAssertHelp<C: ParsableCommand>(_ command: C.Type, expected: String, file: StaticString = #filePath, line: UInt = #line) {
    let help = command.helpMessage()
    XCTAssertTrue(help.contains(expected), file: file, line: line)
}

func XCTAssertVersion<C: ParsableCommand>(_ command: C.Type, _ expected: String, file: StaticString = #filePath, line: UInt = #line) {
    XCTAssertEqual(command.configuration.version, expected, file: file, line: line)
}

func XCTAssertExit(_ closure: () throws -> Void, file: StaticString = #filePath, line: UInt = #line) {
    XCTAssertThrowsError(try closure(), file: file, line: line)
}

final class RenderCLITests: XCTestCase {
    func testHelpFlag() {
        XCTAssertHelp(RenderCLI.self, expected: "USAGE:")
    }

    func testVersionFlag() {
        XCTAssertVersion(RenderCLI.self, "0.1.0")
    }

    func testUnknownFlag() {
        XCTAssertExit { try RenderCLI.parse(["--unknown"]) }
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.

