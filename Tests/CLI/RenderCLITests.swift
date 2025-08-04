import XCTest
import ArgumentParser
@testable import RenderCLI
#if os(Linux)
import Glibc
#else
import Darwin
#endif

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

    func testEnvironmentFallback() throws {
        setenv("TEATRO_WIDTH", "800", 1)
        setenv("TEATRO_HEIGHT", "600", 1)
        defer {
            unsetenv("TEATRO_WIDTH")
            unsetenv("TEATRO_HEIGHT")
            unsetenv("TEATRO_SVG_WIDTH")
            unsetenv("TEATRO_IMAGE_WIDTH")
            unsetenv("TEATRO_SVG_HEIGHT")
            unsetenv("TEATRO_IMAGE_HEIGHT")
        }
        let cli = try RenderCLI.parse([])
        try cli.run()
        XCTAssertEqual(String(cString: getenv("TEATRO_SVG_WIDTH")), "800")
        XCTAssertEqual(String(cString: getenv("TEATRO_IMAGE_WIDTH")), "800")
        XCTAssertEqual(String(cString: getenv("TEATRO_SVG_HEIGHT")), "600")
        XCTAssertEqual(String(cString: getenv("TEATRO_IMAGE_HEIGHT")), "600")
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.

