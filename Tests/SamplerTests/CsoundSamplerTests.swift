import XCTest
@testable import Teatro

final class CsoundSamplerTests: XCTestCase {
    func testCsoundSamplerLifecycle() async throws {
        let path = FileManager.default.currentDirectoryPath + "/assets/sine.orc"
        weak var weakSampler: CsoundSampler?
        do {
            let sampler = CsoundSampler()
            weakSampler = sampler
            try await sampler.loadInstrument(path)
            await sampler.trigger(MIDI2Note(channel: 0, note: 60, velocity: 1.0, duration: 0.1))
            await sampler.stopAll()
        }
        await Task.yield()
        XCTAssertNil(weakSampler)
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
