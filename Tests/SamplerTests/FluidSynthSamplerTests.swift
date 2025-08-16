import XCTest
import MIDI2
@testable import Teatro

final class FluidSynthSamplerTests: XCTestCase {
    func testFluidSynthSamplerLifecycle() async throws {
        let path = FileManager.default.currentDirectoryPath + "/assets/example.sf2"
        weak var weakSampler: FluidSynthSampler?
        do {
            let sampler = FluidSynthSampler()
            weakSampler = sampler
            try await sampler.loadInstrument(path)
            let vel = UInt16((MIDI.fromUnitFloat(0.8) >> 16) & 0xFFFF)
            let on = Midi2NoteOn(group: Uint4(0)!, channel: Uint4(0)!, note: Uint7(60)!, velocity: vel)
            try await sampler.noteOn(on)
            try? await Task.sleep(nanoseconds: 5_000_000)
            let off = Midi2NoteOff(group: Uint4(0)!, channel: Uint4(0)!, noteNumber: Uint7(60)!, velocity: 0)
            try await sampler.noteOff(off)
            await sampler.stopAll()
        }
        await Task.yield()
        XCTAssertNil(weakSampler)
    }

    func testNoteOnWithoutLoadDoesNothing() async {
        let sampler = FluidSynthSampler()
        let vel = UInt16((MIDI.fromUnitFloat(0.5) >> 16) & 0xFFFF)
        let on = Midi2NoteOn(group: Uint4(0)!, channel: Uint4(0)!, note: Uint7(60)!, velocity: vel)
        try? await sampler.noteOn(on)
        await sampler.stopAll()
    }

}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
