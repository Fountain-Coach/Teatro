import Foundation
import Teatro

let group = DispatchGroup()

group.enter()
Task {
    let sf2 = Bundle.module.path(forResource: "example", ofType: "sf2") ?? "assets/example.sf2"
    if let sampler = try? await TeatroSampler(backend: .fluidsynth(sf2Path: sf2)) {
        let note = MIDI2Note(channel: 0, note: 60, velocity: 0.8, duration: 1.0)
        await sampler.trigger(note)
        await sampler.stopAll()
    }
    group.leave()
}

group.wait()
