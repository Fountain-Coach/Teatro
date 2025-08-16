import XCTest
import Foundation
import ArgumentParser
@testable import RenderCLI
@testable import Teatro
import MIDI2

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
        let base64 = try String(contentsOf: fixtures.appendingPathComponent("sample.mid"), encoding: .utf8).components(separatedBy: "\n").first ?? ""
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
        let vel = UInt16((MIDI.fromUnitFloat(1.0) >> 16) & 0xFFFF)
        let packets = UMPEncoder.encode(Midi2NoteOn(group: Uint4(0)!, channel: Uint4(0)!, note: Uint7(60)!, velocity: vel))
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
        let contents = try String(contentsOf: url, encoding: .utf8)
        XCTAssertTrue(contents.contains("<svg"))
    }

    func testPNGOutputWritesFile() throws {
        let url = tempURL("out.png")
        defer { try? FileManager.default.removeItem(at: url) }
        let cli = try RenderCLI.parse(["--format", "png", "--output", url.path])
        XCTAssertNoThrow(try cli.run())
        if !FileManager.default.fileExists(atPath: url.path) {
            let alt = url.deletingPathExtension().appendingPathExtension("svg")
            XCTAssertTrue(FileManager.default.fileExists(atPath: alt.path))
        }
    }

    func testMarkdownOutputWritesFile() throws {
        let url = tempURL("out.md")
        defer { try? FileManager.default.removeItem(at: url) }
        let cli = try RenderCLI.parse(["--format", "markdown", "--output", url.path])
        XCTAssertNoThrow(try cli.run())
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
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
        let contents = try String(contentsOf: output, encoding: .utf8)
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
        let vel = UInt16((MIDI.fromUnitFloat(1.0) >> 16) & 0xFFFF)
        let packets = UMPEncoder.encode(Midi2NoteOn(group: Uint4(0)!, channel: Uint4(0)!, note: Uint7(60)!, velocity: vel))
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

    func testRunWithoutArguments() throws {
        let cli = try RenderCLI.parse([])
        XCTAssertNoThrow(try cli.run())
    }

    func testRunAppliesWidthAndHeightOptions() throws {
        let cli = try RenderCLI.parse(["--width", "123", "--height", "321"])
        try cli.run()
        XCTAssertEqual(String(cString: getenv("TEATRO_SVG_WIDTH")), "123")
        XCTAssertEqual(String(cString: getenv("TEATRO_IMAGE_WIDTH")), "123")
        XCTAssertEqual(String(cString: getenv("TEATRO_SVG_HEIGHT")), "321")
        XCTAssertEqual(String(cString: getenv("TEATRO_IMAGE_HEIGHT")), "321")
    }

    func testSvgAnimatedFormatRequiresStoryboard() throws {
        let cli = try RenderCLI.parse(["--format", "svgAnimated"])
        XCTAssertThrowsError(try cli.run())
    }

    func testCsoundFormatRequiresScore() throws {
        let cli = try RenderCLI.parse(["--format", "csound"])
        XCTAssertThrowsError(try cli.run())
    }

    func testUMPFormatRequiresMIDI() throws {
        let cli = try RenderCLI.parse(["--format", "ump"])
        XCTAssertThrowsError(try cli.run())
    }

    func testMidiEventViewRendersAllCases() throws {
        let events: [MidiEventProtocol] = [
            ChannelVoiceEvent(timestamp: 0, type: .noteOn, group: nil, channel: 0, noteNumber: 60, velocity: 64, controllerValue: nil),
            ChannelVoiceEvent(timestamp: 1, type: .noteOff, group: nil, channel: 0, noteNumber: 60, velocity: 0, controllerValue: nil),
            ChannelVoiceEvent(timestamp: 2, type: .controlChange, group: nil, channel: 0, noteNumber: 1, velocity: nil, controllerValue: 2),
            ChannelVoiceEvent(timestamp: 3, type: .programChange, group: nil, channel: 0, noteNumber: nil, velocity: nil, controllerValue: 5),
            ChannelVoiceEvent(timestamp: 4, type: .pitchBend, group: nil, channel: 0, noteNumber: nil, velocity: nil, controllerValue: 0x2000),
            ChannelVoiceEvent(timestamp: 5, type: .channelPressure, group: nil, channel: 0, noteNumber: nil, velocity: nil, controllerValue: 3),
            ChannelVoiceEvent(timestamp: 6, type: .polyphonicKeyPressure, group: nil, channel: 0, noteNumber: 61, velocity: 70, controllerValue: nil),
            MetaEvent(timestamp: 7, meta: 0x2F, data: Data()),
            DummySysExEvent(timestamp: 8, bytes: Data([0x00])),
            DummyUnknownEvent(timestamp: 9)
        ]
        let view = MidiEventView(events: events)
        let out = view.render()
        XCTAssertTrue(out.contains("noteOn"))
        XCTAssertTrue(out.contains("noteOff"))
        XCTAssertTrue(out.contains("cc"))
        XCTAssertTrue(out.contains("program"))
        XCTAssertTrue(out.contains("pitch"))
        XCTAssertTrue(out.contains("pressure"))
        XCTAssertTrue(out.contains("polyPressure"))
        XCTAssertTrue(out.contains("meta"))
        XCTAssertTrue(out.contains("sysex"))
        XCTAssertTrue(out.contains("unknown"))
    }

    #if canImport(Darwin)
    func testWatchFileDarwinReturnsSource() {
        let cli = RenderCLI()
        let url = tempURL("watch.txt")
        FileManager.default.createFile(atPath: url.path, contents: Data())
        defer { try? FileManager.default.removeItem(at: url) }
        let source = cli.watchFile(path: url.path, target: MarkdownRenderer.self, outputPath: nil)
        XCTAssertNotNil(source)
        source?.cancel()
    }
    #endif

#if !canImport(Darwin)
    func testWatchModeRerendersOnChangeLinux() throws {
        throw XCTSkip("Watch mode not supported in CI environment")
    }
#endif

    func testRenderCLIMainExecutable() throws {
        let exec = productsDirectory.appendingPathComponent("RenderCLI")
        guard FileManager.default.fileExists(atPath: exec.path) else {
            XCTFail("Executable not found at \(exec.path)")
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

private var productsDirectory: URL {
#if os(macOS)
    for bundle in Bundle.allBundles where bundle.bundlePath.hasSuffix(".xctest") {
        return bundle.bundleURL.deletingLastPathComponent()
    }
    fatalError("Could not locate products directory")
#else
    return Bundle.main.bundleURL
#endif
}

struct DummySysExEvent: MidiEventProtocol {
    let timestamp: UInt32
    let bytes: Data
    var type: MidiEventType { .sysEx }
    var group: UInt8? { nil }
    var channel: UInt8? { nil }
    var noteNumber: UInt8? { nil }
    var velocity: UInt32? { nil }
    var controllerValue: UInt32? { nil }
    var metaType: UInt8? { nil }
    var rawData: Data? { bytes }
}

struct DummyUnknownEvent: MidiEventProtocol {
    let timestamp: UInt32
    var type: MidiEventType { .unknown }
    var group: UInt8? { nil }
    var channel: UInt8? { nil }
    var noteNumber: UInt8? { nil }
    var velocity: UInt32? { nil }
    var controllerValue: UInt32? { nil }
    var metaType: UInt8? { nil }
    var rawData: Data? { nil }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
