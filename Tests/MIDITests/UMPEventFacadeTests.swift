import XCTest
import MIDI2
@testable import Teatro

final class UMPEventFacadeTests: XCTestCase {
    func testNoteOnRoundTrip() {
        let note = Midi2NoteOn(
            group: Uint4(0)!,
            channel: Uint4(1)!,
            note: Uint7(60)!,
            velocity: 0x1234
        )
        let packet = note.ump()
        guard let event = UMPEvent(words: packet.words) else {
            XCTFail("Failed to parse packet")
            return
        }
        guard case .channelVoice(let body) = event else {
            XCTFail("Expected channelVoice event")
            return
        }
        XCTAssertEqual(body, Midi2ChannelVoiceBody(ump: packet)!)
        XCTAssertEqual(event.words, packet.words)
    }
}
