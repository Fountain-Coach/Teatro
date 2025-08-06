import XCTest
import Foundation
import ArgumentParser
@testable import RenderCLI
import Teatro

final class RenderCLICoverageTests: XCTestCase {
    private func tempURL(_ name: String) -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent(name)
    }

    func testWatchFlagWithoutInputDoesNotDispatch() throws {
        let cli = try RenderCLI.parse(["--watch"])
        XCTAssertNoThrow(try cli.run())
    }

    func testDetermineTargetInference() throws {
        let temp = FileManager.default.temporaryDirectory
        let files = ["inf.svg", "inf.png", "inf.codex"]
        for file in files {
            let url = temp.appendingPathComponent(file)
            defer { try? FileManager.default.removeItem(at: url) }
            let cli = try RenderCLI.parse(["--output", url.path])
            XCTAssertNoThrow(try cli.run())
            if !FileManager.default.fileExists(atPath: url.path) {
                let alt = url.deletingPathExtension().appendingPathExtension("svg")
                XCTAssertTrue(FileManager.default.fileExists(atPath: alt.path))
            }
        }
        let csdURL = temp.appendingPathComponent("inf.csd")
        let cliCSD = try RenderCLI.parse(["--output", csdURL.path])
        XCTAssertThrowsError(try cliCSD.run())
        let unknownURL = temp.appendingPathComponent("inf.xyz")
        defer { try? FileManager.default.removeItem(at: unknownURL) }
        let cliUnknown = try RenderCLI.parse(["--output", unknownURL.path])
        XCTAssertNoThrow(try cliUnknown.run())
    }

    func testFountainInputLoads() throws {
        let text = "Title: Test\nINT. ROOM - DAY\n"
        let url = tempURL("test.fountain")
        try text.write(to: url, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: url) }
        let cli = try RenderCLI.parse([url.path])
        XCTAssertNoThrow(try cli.run())
    }

    func testLilypondInputLoads() throws {
        let text = "c'4"
        let url = tempURL("test.ly")
        try text.write(to: url, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: url) }
        let cli = try RenderCLI.parse([url.path])
        XCTAssertNoThrow(try cli.run())
    }

    func testCsoundInputLoads() throws {
        let text = "<Orchestra>instr 1\nendin</Orchestra>\n<Score>i1 0 1 440</Score>"
        let url = tempURL("test.csd")
        try text.write(to: url, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: url) }
        let cli = try RenderCLI.parse([url.path])
        XCTAssertNoThrow(try cli.run())
    }

    func testMidiSignatureFallbackParses() throws {
        let fixtures = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Fixtures")
        let base64 = try String(contentsOf: fixtures.appendingPathComponent("sample.mid")).components(separatedBy: "\n").first ?? ""
        let data = Data(base64Encoded: base64)!
        let url = tempURL("sample.bin")
        try data.write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }
        let output = try captureStdout {
            let cli = try RenderCLI.parse([url.path])
            try cli.run()
        }
        XCTAssertTrue(output.contains("meta"))
    }

    func testUMPDetectionByLength() throws {
        let packets = UMPEncoder.encode(MIDI2Note(channel: 0, note: 60, velocity: 1.0, duration: 1.0))
        var data = Data()
        for word in packets {
            var be = word.bigEndian
            withUnsafeBytes(of: &be) { data.append(contentsOf: $0) }
        }
        let url = tempURL("note.bin")
        try data.write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }
        let output = try captureStdout {
            let cli = try RenderCLI.parse([url.path])
            try cli.run()
        }
        XCTAssertTrue(output.contains("noteOn"))
    }

    func testUnknownBinaryThrows() throws {
        let url = tempURL("bad.bin")
        try Data([0x00, 0x01, 0x02]).write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }
        let cli = try RenderCLI.parse([url.path])
        XCTAssertThrowsError(try cli.run()) { error in
            guard let val = error as? ValidationError, val.description.contains("Unsupported") else {
                XCTFail("Expected unsupported extension error")
                return
            }
        }
    }

    func testHTMLOutputWritesFile() throws {
        let url = tempURL("out.html")
        defer { try? FileManager.default.removeItem(at: url) }
        let cli = try RenderCLI.parse(["--format", "html", "--output", url.path])
        XCTAssertNoThrow(try cli.run())
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
    }

    func testSVGOutputWritesFile() throws {
        let url = tempURL("out.svg")
        defer { try? FileManager.default.removeItem(at: url) }
        let cli = try RenderCLI.parse(["--format", "svg", "--output", url.path])
        XCTAssertNoThrow(try cli.run())
        let contents = try String(contentsOf: url)
        XCTAssertTrue(contents.contains("<svg"))
    }

    func testSvgAnimatedStoryboardRenders() throws {
        let text = """
        Scene: One
        Text: Hi
        """
        let input = tempURL("anim.storyboard")
        try text.write(to: input, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: input) }
        let output = tempURL("anim.svg")
        defer { try? FileManager.default.removeItem(at: output) }
        let cli = try RenderCLI.parse([input.path, "--format", "svgAnimated", "--output", output.path, "--force-format"])
        XCTAssertNoThrow(try cli.run())
        let contents = try String(contentsOf: output)
        XCTAssertTrue(contents.contains("<svg"))
    }

    func testCsoundRenderingWritesFile() throws {
        let text = "<Orchestra>instr 1\nendin</Orchestra>\n<Score>i1 0 1 440</Score>"
        let input = tempURL("score.csd")
        try text.write(to: input, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: input) }
        let output = tempURL("score.csd")
        defer { try? FileManager.default.removeItem(at: output) }
        let cli = try RenderCLI.parse([input.path, "--format", "csound", "--output", output.path])
        XCTAssertNoThrow(try cli.run())
        XCTAssertTrue(FileManager.default.fileExists(atPath: output.path))
    }

    func testUMPOutputToStdoutHex() throws {
        let packets = UMPEncoder.encode(MIDI2Note(channel: 0, note: 60, velocity: 1.0, duration: 1.0))
        var data = Data()
        for word in packets {
            var be = word.bigEndian
            withUnsafeBytes(of: &be) { data.append(contentsOf: $0) }
        }
        let url = tempURL("stdout.ump")
        try data.write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }
        let output = try captureStdout {
            let cli = try RenderCLI.parse([url.path, "--format", "ump"])
            try cli.run()
        }
        XCTAssertFalse(output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    #if !canImport(Darwin)
    func testWatchModeRerendersOnChangeLinux() throws {
        let text = """
        Scene: One
        Text: Start
        """
        let input = tempURL("watch.storyboard")
        try text.write(to: input, atomically: true, encoding: .utf8)
        let output = tempURL("watch.md")
        defer {
            try? FileManager.default.removeItem(at: input)
            try? FileManager.default.removeItem(at: output)
        }
        let cli = RenderCLI()
        let source = cli.watchFile(path: input.path, target: .markdown, outputPath: output.path)
        let exp = expectation(description: "rerender")
        DispatchQueue.global().asyncAfter(deadline: .now() + 2.0) {
            try? """
            Scene: One
            Text: Changed
            """.write(to: input, atomically: true, encoding: .utf8)
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + 4.0) {
            if let contents = try? String(contentsOf: output), contents.contains("Changed") {
                exp.fulfill()
            }
        }
        wait(for: [exp], timeout: 6)
        source?.cancel()
    }
    #endif

    func testRenderCLIMainExecutable() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let build = root.appendingPathComponent(".build")
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(at: build, includingPropertiesForKeys: nil) else {
            XCTFail("No build directory")
            return
        }
        var exe: URL?
        for case let url as URL in enumerator {
            if url.lastPathComponent == "RenderCLI" { exe = url; break }
        }
        guard let exec = exe else {
            XCTFail("Executable not found")
            return
        }
        let process = Process()
        process.executableURL = exec
        process.arguments = ["--version"]
        let pipe = Pipe()
        process.standardOutput = pipe
        try process.run()
        process.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(decoding: data, as: UTF8.self)
        XCTAssertTrue(output.contains("0.1.0"))
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
