import XCTest
import MIDI2
@testable import Teatro

final class CsoundSamplerTests: XCTestCase {
    func testCsoundSamplerLifecycle() async throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // CsoundSamplerTests.swift
            .deletingLastPathComponent() // SamplerTests
            .deletingLastPathComponent() // Tests
        let path = root.appendingPathComponent("assets/sine.orc").path
        guard FileManager.default.fileExists(atPath: path) else {
            XCTFail("Missing resource at \(path)")
            return
        }
        weak var weakSampler: CsoundSampler?
        do {
            let sampler = CsoundSampler()
            weakSampler = sampler
            try await sampler.loadInstrument(path)
            // Allow the background performance loop to spin at least once
            try? await Task.sleep(nanoseconds: 1_000_000)
            let vel = UInt16((MIDI.fromUnitFloat(1.0) >> 16) & 0xFFFF)
            let on = Midi2NoteOn(group: Uint4(0)!, channel: Uint4(0)!, note: Uint7(60)!, velocity: vel)
            try await sampler.noteOn(on)
            await sampler.stopAll()
        }
        await Task.yield()
        XCTAssertNil(weakSampler)
    }

    func testNoteOnWithoutLoadDoesNothing() async {
        let sampler = CsoundSampler()
        let vel = UInt16((MIDI.fromUnitFloat(1.0) >> 16) & 0xFFFF)
        let on = Midi2NoteOn(group: Uint4(0)!, channel: Uint4(0)!, note: Uint7(60)!, velocity: vel)
        try? await sampler.noteOn(on)
        await sampler.stopAll()
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
