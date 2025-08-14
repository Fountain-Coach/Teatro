import XCTest
@testable import Teatro

final class FluidSynthSinkTests: XCTestCase {
    func testSinkPlaysNote() throws {
        let path = FileManager.default.currentDirectoryPath + "/assets/example.sf2"
        let sink = try FluidSynthSink(sf2Path: path)
        sink.noteOn(note: 60, vel: 100, ch: 0)
        sink.noteOff(note: 60, ch: 0)
        sink.controlChange(cc: 1, value: 2, ch: 0)
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
