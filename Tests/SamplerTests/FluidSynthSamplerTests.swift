import XCTest
@testable import Teatro

final class FluidSynthSamplerTests: XCTestCase {
    func testFluidSynthSamplerLifecycle() async throws {
        let path = FileManager.default.currentDirectoryPath + "/assets/example.sf2"
        weak var weakSampler: FluidSynthSampler?
        do {
            let sampler = FluidSynthSampler()
            weakSampler = sampler
            try await sampler.loadInstrument(path)
            await sampler.trigger(MIDI2Note(channel: 0, note: 60, velocity: MIDI.fromUnitFloat(0.8), duration: 0.001))
            try? await Task.sleep(nanoseconds: 5_000_000)
            await sampler.stopAll()
        }
        await Task.yield()
        XCTAssertNil(weakSampler)
    }

    func testTriggerWithoutLoadDoesNothing() async {
        let sampler = FluidSynthSampler()
        await sampler.trigger(MIDI2Note(channel: 0, note: 60, velocity: MIDI.fromUnitFloat(0.5), duration: 0.0))
        await sampler.stopAll()
    }

}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
