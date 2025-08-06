import XCTest
import Foundation
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

func captureStdout(_ closure: () throws -> Void) throws -> String {
    let pipe = Pipe()
    let original = dup(STDOUT_FILENO)
    dup2(pipe.fileHandleForWriting.fileDescriptor, STDOUT_FILENO)
    try closure()
    fflush(nil)
    dup2(original, STDOUT_FILENO)
    close(original)
    pipe.fileHandleForWriting.closeFile()
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    return String(decoding: data, as: UTF8.self)
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
        setenv("TEATRO_SVG_WIDTH", "800", 1)
        setenv("TEATRO_SVG_HEIGHT", "600", 1)
        defer {
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

    func testWidthHeightFlagsOverrideEnv() throws {
        setenv("TEATRO_SVG_WIDTH", "800", 1)
        setenv("TEATRO_IMAGE_WIDTH", "800", 1)
        setenv("TEATRO_SVG_HEIGHT", "600", 1)
        setenv("TEATRO_IMAGE_HEIGHT", "600", 1)
        defer {
            unsetenv("TEATRO_SVG_WIDTH")
            unsetenv("TEATRO_IMAGE_WIDTH")
            unsetenv("TEATRO_SVG_HEIGHT")
            unsetenv("TEATRO_IMAGE_HEIGHT")
        }
        let cli = try RenderCLI.parse(["--width", "1024", "--height", "768"])
        try cli.run()
        XCTAssertEqual(String(cString: getenv("TEATRO_SVG_WIDTH")), "1024")
        XCTAssertEqual(String(cString: getenv("TEATRO_IMAGE_WIDTH")), "1024")
        XCTAssertEqual(String(cString: getenv("TEATRO_SVG_HEIGHT")), "768")
        XCTAssertEqual(String(cString: getenv("TEATRO_IMAGE_HEIGHT")), "768")
    }

    func testCodexOutputToStdout() throws {
        let output = try captureStdout {
            let cli = try RenderCLI.parse([])
            try cli.run()
        }
        XCTAssertTrue(output.contains("[Stage: CLI Demo]"))
    }

    func testFileOutputWritesMessage() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("out.md")
        defer { try? FileManager.default.removeItem(at: url) }
        let output = try captureStdout {
            let cli = try RenderCLI.parse(["--format", "markdown", "--output", url.path])
            try cli.run()
        }
        XCTAssertTrue(output.contains("Wrote \(url.path)"))
    }

    func testMidiSignatureRecognition() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("sigtest.bin")
        defer { try? FileManager.default.removeItem(at: url) }
        try Data([0x4d, 0x54, 0x68, 0x64]).write(to: url) // "MThd"
        let cli = try RenderCLI.parse([url.path])
        XCTAssertThrowsError(try cli.run()) { error in
            guard let val = error as? ValidationError, val.description.contains("MIDI") else {
                XCTFail("Expected MIDI signature error")
                return
            }
        }
    }

    func testMidiFixtureFileThrows() throws {
        let fixtures = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Fixtures")
        let base64 = try String(contentsOf: fixtures.appendingPathComponent("sample.mid")).components(separatedBy: "\n").first ?? ""
        let data = Data(base64Encoded: base64)!
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("fixture.mid")
        try data.write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }
        let cli = try RenderCLI.parse([url.path])
        XCTAssertThrowsError(try cli.run()) { error in
            guard let val = error as? ValidationError, val.description.contains("MIDI") else {
                XCTFail("Expected MIDI parsing error")
                return
            }
        }
    }

    func testUMPSignatureRecognition() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("umptest.bin")
        defer { try? FileManager.default.removeItem(at: url) }
        try Data([0x20, 0x00, 0x00, 0x00]).write(to: url) // single UMP word
        let cli = try RenderCLI.parse([url.path])
        XCTAssertThrowsError(try cli.run()) { error in
            guard let val = error as? ValidationError, val.description.contains("UMP") else {
                XCTFail("Expected UMP signature error")
                return
            }
        }
    }

    func testUMPOutputWritesFile() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("out.ump")
        defer { try? FileManager.default.removeItem(at: url) }
        let cli = try RenderCLI.parse(["--format", "ump", "--output", url.path])
        try cli.run()
        let data = try Data(contentsOf: url)
        XCTAssertEqual(data.count, 8)
    }

    func testOutputExtensionMismatchThrows() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("mismatch.html")
        defer { try? FileManager.default.removeItem(at: url) }
        let cli = try RenderCLI.parse(["--format", "png", "--output", url.path])
        XCTAssertThrowsError(try cli.run()) { error in
            guard error is ValidationError else {
                XCTFail("Expected ValidationError")
                return
            }
        }
    }

    func testForceFormatOverridesMismatch() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("forced.html")
        defer { try? FileManager.default.removeItem(at: url) }
        let cli = try RenderCLI.parse(["--format", "png", "--output", url.path, "--force-format"])
        XCTAssertNoThrow(try cli.run())
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
    }

    func testStoryboardInputRenders() throws {
        let text = """
        Scene: One
        Text: Hi
        """
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("test.storyboard")
        try text.write(to: url, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: url) }
        let cli = try RenderCLI.parse([url.path])
        XCTAssertNoThrow(try cli.run())
    }

    func testSessionInputRenders() throws {
        let text = "session log"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("test.session")
        try text.write(to: url, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: url) }
        let cli = try RenderCLI.parse([url.path])
        XCTAssertNoThrow(try cli.run())
    }

#if canImport(Darwin)
    func testWatchModeRerendersOnChange() throws {
        let text = """
        Scene: One
        Text: Start
        """
        let input = FileManager.default.temporaryDirectory.appendingPathComponent("watch.storyboard")
        let output = FileManager.default.temporaryDirectory.appendingPathComponent("watch.md")
        try text.write(to: input, atomically: true, encoding: .utf8)
        defer {
            try? FileManager.default.removeItem(at: input)
            try? FileManager.default.removeItem(at: output)
        }
        let cli = RenderCLI()
        let source = cli.watchFile(path: input.path, target: .markdown, outputPath: output.path)
        let exp = expectation(description: "rerender")
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
            try? """
            Scene: One
            Text: Changed
            """.write(to: input, atomically: true, encoding: .utf8)
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + 2.0) {
            if let contents = try? String(contentsOf: output), contents.contains("Changed") {
                exp.fulfill()
            }
        }
        wait(for: [exp], timeout: 5)
        source?.cancel()
    }
#endif
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.

