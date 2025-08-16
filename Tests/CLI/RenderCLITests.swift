import XCTest
import Foundation
import ArgumentParser
@testable import RenderCLI
import Teatro
import MIDI2
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
        XCTAssertExit { _ = try RenderCLI.parse(["--unknown"]) }
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

    func testMidiFixtureFileParses() throws {
        let fixtures = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Fixtures")
        let base64 = try String(contentsOf: fixtures.appendingPathComponent("sample.mid"), encoding: .utf8).components(separatedBy: "\n").first ?? ""
        let data = Data(base64Encoded: base64)!
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("fixture.mid")
        try data.write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }
        let output = try captureStdout {
            let cli = try RenderCLI.parse([url.path])
            try cli.run()
        }
        XCTAssertTrue(output.contains("meta"))
    }

    func testUMPMisalignedThrows() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("umptest.ump")
        defer { try? FileManager.default.removeItem(at: url) }
        try Data([0x20, 0x00, 0x00]).write(to: url) // misaligned
        let cli = try RenderCLI.parse([url.path])
        XCTAssertThrowsError(try cli.run()) { error in
            guard let val = error as? ValidationError, val.description.contains("UMP") else {
                XCTFail("Expected UMP misalignment error")
                return
            }
        }
    }

    func testUMPFileParses() throws {
        let vel = UInt16((MIDI.fromUnitFloat(1.0) >> 16) & 0xFFFF)
        let packets = UMPEncoder.encode(Midi2NoteOn(group: Uint4(0)!, channel: Uint4(0)!, note: Uint7(60)!, velocity: vel))
        var data = Data()
        for word in packets {
            var be = word.bigEndian
            withUnsafeBytes(of: &be) { data.append(contentsOf: $0) }
        }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("note.ump")
        try data.write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }
        let output = try captureStdout {
            let cli = try RenderCLI.parse([url.path])
            try cli.run()
        }
        XCTAssertTrue(output.contains("noteOn"))
    }

    func testUMPOutputEncodesInput() throws {
        let vel = UInt16((MIDI.fromUnitFloat(1.0) >> 16) & 0xFFFF)
        let packets = UMPEncoder.encode(Midi2NoteOn(group: Uint4(0)!, channel: Uint4(0)!, note: Uint7(60)!, velocity: vel))
        var inputData = Data()
        for word in packets {
            var be = word.bigEndian
            withUnsafeBytes(of: &be) { inputData.append(contentsOf: $0) }
        }
        let inputURL = FileManager.default.temporaryDirectory.appendingPathComponent("in.ump")
        try inputData.write(to: inputURL)
        defer { try? FileManager.default.removeItem(at: inputURL) }
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("out.ump")
        defer { try? FileManager.default.removeItem(at: outputURL) }
        let cli = try RenderCLI.parse([inputURL.path, "--format", "ump", "--output", outputURL.path])
        try cli.run()
        let outData = try Data(contentsOf: outputURL)
        let events = try UMPParser.parse(data: inputData)
        let expectedWords = UMPEncoder.encodeEvents(events)
        var expected = Data()
        for word in expectedWords {
            var be = word.bigEndian
            withUnsafeBytes(of: &be) { expected.append(contentsOf: $0) }
        }
        XCTAssertEqual(outData, expected)
    }

    func testUMPRequiresMidiInput() throws {
        let cli = try RenderCLI.parse(["--format", "ump"])
        XCTAssertThrowsError(try cli.run()) { error in
            guard let val = error as? ValidationError, val.description.contains("UMP output requires") else {
                XCTFail("Expected UMP input validation error")
                return
            }
        }
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
        let source = try cli.watchFile(path: input.path, target: MarkdownRenderer.self, outputPath: output.path)
        let exp = expectation(description: "rerender")
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
            try? """
            Scene: One
            Text: Changed
            """.write(to: input, atomically: true, encoding: .utf8)
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + 2.0) {
            if let contents = try? String(contentsOf: output, encoding: .utf8), contents.contains("Changed") {
                exp.fulfill()
            }
        }
        wait(for: [exp], timeout: 5)
        source?.cancel()
    }
#endif

#if !canImport(Darwin)
    func testWatchModeRerendersOnChangeLinux() throws {
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
        let source = try cli.watchFile(path: input.path, target: MarkdownRenderer.self, outputPath: output.path)
        let exp = expectation(description: "rerender")
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
            try? """
            Scene: One
            Text: Changed
            """.write(to: input, atomically: true, encoding: .utf8)
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + 3.0) {
            if let contents = try? String(contentsOf: output, encoding: .utf8), contents.contains("Changed") {
                exp.fulfill()
            }
        }
        wait(for: [exp], timeout: 6)
        source?.cancel()
    }
#endif
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.

