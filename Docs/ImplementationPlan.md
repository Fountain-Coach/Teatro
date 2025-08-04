# Implementation Plan

## Status Quo

- CLI handles `.fountain`, `.ly`, and `.csd` inputs; `.storyboard`, `.mid`/`.midi`, `.ump`, and `.session` inputs remain unimplemented, though MIDI and UMP files are now detected by signature.
- UMP rendering target encodes a placeholder UMP packet; full integration with parsers is pending.
- Environment variables for width/height now apply even when flags are absent.
- Watch mode uses `DispatchSource.makeFileSystemObjectSource` for file monitoring on supported platforms and falls back to polling on Linux.
- Tests cover help/version output, unknown flags, SMF header/track parsing (including running status, Control Change, Program Change, Pitch Bend decoding, timestamp accumulation, and error handling for invalid headers, tracks, and events), and UMP parsing for SysEx7/SysEx8, group/channel mapping, and error cases. Csound and FluidSynth headers are vendored for consistent builds.
- Regression test ensures running status decoding in MidiFileParser.
- `MidiFileParser` parses SMF header, track events, channel voice messages (Note On/Off, Control Change, Program Change, Pitch Bend, Channel Pressure, Polyphonic Key Pressure), preserves system common and real-time messages as `UnknownEvent` and clears running status after them, accumulates delta times into absolute timestamps, normalizes Note On events with velocity 0 to Note Off, decodes SysEx events, validates track chunk lengths, and meta events (track name via `TrackNameEvent`, tempo, time signature, key signature, lyrics via `LyricEvent`); remaining message types remain pending.
- Unknown meta events and SysEx events are preserved and unit tests verify this behavior.
- `UMPParser` decodes utility, system real-time/common, SysEx7 and SysEx8, MIDI 1.0 and MIDI 2.0 channel voice messages (including Program Change, Pitch Bend, Channel Pressure, and Polyphonic Key Pressure) and normalizes Note On velocity 0 to Note Off for MIDI 1.0 and MIDI 2.0 packets, maps group/channel pairs into unified channel numbers, and validates misaligned or truncated packets; additional UMP message types remain pending.
- Unified MIDI event model introduced; `MidiFileParser` and `UMPParser` emit protocol-based events.

## Action Plan

1. Implement parsers and renderers for `.storyboard`, `.mid`/`.midi`, `.ump`, and `.session` files (SMF header parser implemented).
2. ~~Add `ump` output target in the render dispatcher and ensure all formats are documented.~~
3. ~~Apply environment variable fallback when width/height flags are absent and add tests for precedence.~~
4. ~~Replace polling watch mode with `DispatchSource.makeFileSystemObjectSource` on platforms that support it.~~
5. Expand test suite to cover argument parsing, watch/dispatch logic, output correctness, and environment variable precedence.
6. Document integrated audio backends and note that Csound/FluidSynth headers are bundled with the source.
7. Update CLI help text and docs to reflect new inputs, outputs, and features.
8. Maintain this file with up-to-date status and tasks as work progresses.

---

© 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
