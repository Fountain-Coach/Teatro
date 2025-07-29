import XCTest
@testable import Teatro

final class TeatroSamplerTests: XCTestCase {
    actor MockSource: SampleSource {
        private var triggered: [MIDI2Note] = []
        func trigger(_ note: MIDI2Note) async { triggered.append(note) }
        func stopAll() async { triggered.removeAll() }
        func loadInstrument(_ path: String) async throws {}
        func notes() async -> [MIDI2Note] { triggered }
    }

    func testTriggerDelegates() async throws {
        let mock = MockSource()
        let sampler = TeatroSampler(implementation: mock)
        let note = MIDI2Note(channel: 0, note: 60, velocity: 1.0, duration: 1.0)
        await sampler.trigger(note)
        let triggered = await mock.notes()
        XCTAssertEqual(triggered.first, note)
    }
}
