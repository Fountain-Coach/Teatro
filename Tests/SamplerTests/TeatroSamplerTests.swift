import XCTest
@testable import Teatro

final class TeatroSamplerTests: XCTestCase {
    actor MockSource: SampleSource {
        private var triggered: [MIDI2Note] = []
        private var loaded: [String] = []
        private var stopped = false

        func trigger(_ note: MIDI2Note) async { triggered.append(note) }
        func stopAll() async { stopped = true }
        func loadInstrument(_ path: String) async throws { loaded.append(path) }

        func notes() async -> [MIDI2Note] { triggered }
        func loadedPaths() async -> [String] { loaded }
        func didStop() async -> Bool { stopped }
    }

    func testTriggerDelegates() async throws {
        let mock = MockSource()
        let sampler = TeatroSampler(implementation: mock)
        let note = MIDI2Note(channel: 0, note: 60, velocity: 1.0, duration: 1.0)
        await sampler.trigger(note)
        let triggered = await mock.notes()
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
}
