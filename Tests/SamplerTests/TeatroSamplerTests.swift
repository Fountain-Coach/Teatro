import XCTest
import MIDI2
@testable import Teatro

final class TeatroSamplerTests: XCTestCase {
    actor MockSource: SampleSource {
        private var ons: [Midi2NoteOn] = []
        private var offs: [Midi2NoteOff] = []
        private var loaded: [String] = []
        private var stopped = false

        func noteOn(_ note: Midi2NoteOn) async throws { ons.append(note) }
        func noteOff(_ note: Midi2NoteOff) async throws { offs.append(note) }
        func stopAll() async { stopped = true }
        func loadInstrument(_ path: String) async throws { loaded.append(path) }

        func noteOns() async -> [Midi2NoteOn] { ons }
        func noteOffs() async -> [Midi2NoteOff] { offs }
        func loadedPaths() async -> [String] { loaded }
        func didStop() async -> Bool { stopped }
    }

    func testNoteOnDelegates() async throws {
        let mock = MockSource()
        let sampler = TeatroSampler(implementation: mock)
        let vel = UInt16((MIDI.fromUnitFloat(1.0) >> 16) & 0xFFFF)
        let note = Midi2NoteOn(group: Uint4(0)!, channel: Uint4(0)!, note: Uint7(60)!, velocity: vel)
        try await sampler.noteOn(note)
        let triggered = await mock.noteOns()
        XCTAssertEqual(triggered.first, note)
    }

    func testLoadInstrumentDelegates() async throws {
        let mock = MockSource()
        let sampler = TeatroSampler(implementation: mock)
        try await sampler.loadInstrument("instrument.path")
        let paths = await mock.loadedPaths()
        XCTAssertEqual(paths.first, "instrument.path")
    }

    func testStopAllDelegates() async {
        let mock = MockSource()
        let sampler = TeatroSampler(implementation: mock)
        await sampler.stopAll()
        let stopped = await mock.didStop()
        XCTAssertTrue(stopped)
    }

    func testInitWithFluidSynthBackend() async throws {
        guard let url = TeatroResources.bundle.url(forResource: "example", withExtension: "sf2") else {
            XCTFail("Missing example.sf2 in bundle")
            return
        }
        let sampler = try await TeatroSampler(backend: .fluidsynth(sf2Path: url.path))
        await sampler.stopAll()
    }

    func testInitWithCsoundBackend() async throws {
        let sampler = try await TeatroSampler(backend: .csound())
        await sampler.stopAll()
    }
}
