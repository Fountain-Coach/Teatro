import XCTest
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
            await sampler.trigger(MIDI2Note(channel: 0, note: 60, velocity: MIDI.fromUnitFloat(1.0), duration: 0.1))
            await sampler.stopAll()
        }
        await Task.yield()
        XCTAssertNil(weakSampler)
    }

    func testTriggerWithoutLoadDoesNothing() async {
        let sampler = CsoundSampler()
        // Should simply return as no instrument is loaded
        await sampler.trigger(MIDI2Note(channel: 0, note: 60, velocity: MIDI.fromUnitFloat(1.0), duration: 0.1))
        await sampler.stopAll()
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
