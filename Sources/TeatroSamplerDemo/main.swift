import Foundation
import Teatro
import MIDI2

let group = DispatchGroup()

group.enter()
Task {
    let sf2 = Bundle.module.path(forResource: "example", ofType: "sf2") ?? "assets/example.sf2"
    if let sampler = try? await TeatroSampler(backend: .fluidsynth(sf2Path: sf2)) {
        let vel = UInt16((MIDI.fromUnitFloat(0.8) >> 16) & 0xFFFF)
        let on = Midi2NoteOn(group: Uint4(0)!, channel: Uint4(0)!, note: Uint7(60)!, velocity: vel)
        try await sampler.noteOn(on)
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        let off = Midi2NoteOff(group: Uint4(0)!, channel: Uint4(0)!, noteNumber: Uint7(60)!, velocity: 0)
        try await sampler.noteOff(off)
        await sampler.stopAll()
    }
    group.leave()
}

group.wait()
