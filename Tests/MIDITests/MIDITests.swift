import XCTest
@testable import Teatro

final class MIDITests: XCTestCase {
    func testNoteBuilderCollectsNotes() {
        let seq = MIDISequence {
            MIDINote(channel: 0, note: 60, velocity: 100, duration: 0.5)
            MIDINote(channel: 0, note: 62, velocity: 100, duration: 0.5)
        }
        XCTAssertEqual(seq.notes.count, 2)
    }

    func testMIDIRendererOutputsFile() throws {
        let seq = MIDISequence {
            MIDINote(channel: 0, note: 60, velocity: 80, duration: 0.5)
        }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("mid")
        MIDIRenderer.renderToFile(seq, to: url.path)
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        let content = try String(contentsOf: url)
        XCTAssertTrue(content.contains("NOTE"))
    }
}
