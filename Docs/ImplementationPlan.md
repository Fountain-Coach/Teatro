# Implementation Plan

## Status Quo

- CLI handles `.fountain`, `.ly`, and `.csd` inputs; `.storyboard`, `.mid`/`.midi`, `.ump`, and `.session` inputs are unimplemented.
- UMP rendering target is listed but missing from dispatch.
- Environment variable precedence for width/height only applies when flags are set; no fallback to existing variables.
- Watch mode uses a polling loop rather than `DispatchSource.makeFileSystemObjectSource`.
- Tests cover help/version output, unknown flags, and SMF header/track parsing. Csound and FluidSynth headers are vendored for consistent builds.
- `MidiFileParser` parses SMF header, track events, channel voice messages (Note On/Off, Control Change, Program Change, Pitch Bend), and meta events (track name, tempo, time signature); remaining message types remain pending.

## Action Plan

1. Implement parsers and renderers for `.storyboard`, `.mid`/`.midi`, `.ump`, and `.session` files (SMF header parser implemented).
2. Add `ump` output target in the render dispatcher and ensure all formats are documented.
3. Apply environment variable fallback when width/height flags are absent and add tests for precedence.
4. Replace polling watch mode with `DispatchSource.makeFileSystemObjectSource`.
5. Expand test suite to cover argument parsing, watch/dispatch logic, output correctness, and environment variable precedence.
6. Document integrated audio backends and note that Csound/FluidSynth headers are bundled with the source.
7. Update CLI help text and docs to reflect new inputs, outputs, and features.
8. Maintain this file with up-to-date status and tasks as work progresses.

---

© 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
