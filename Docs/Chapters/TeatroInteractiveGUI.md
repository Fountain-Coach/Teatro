# Teatro Interactive GUI (SDL3 + MIDI2)

Status: Beta (stub backend)

This chapter introduces the SDL3-powered GUI backend and its integration with MIDI 2.0 for real-time visualization and control in Teatro. The initial implementation ships a stubbed SDL backend to preserve buildability and determinism while the full SDL path is integrated under a feature flag.

Key modules:
- `TeatroSDLBackend` – window, renderer, event, and run loop abstractions (SDL-free stubs today).
- `MIDIIntegration` – minimal MIDI2 bridging utilities for emitting common UMP messages.
- `TeatroPreviewController` – public API to launch an interactive preview without exposing SDL types.

Design principles:
- Deterministic headless outputs remain unchanged.
- SDL specifics are encapsulated and not exposed publicly.
- Cross-platform friendly structure; Linux builds can use virtual displays later (Xvfb).

Usage:
```
swift run TeatroPreviewDemo
```
This launches a demo preview for ~2 seconds and quits. As the SDL path is stubbed, it renders offscreen and exercises the render loop.

Next steps:
- Introduce real SDL3 bindings and swap-in the concrete implementations behind the same APIs.
- Add device/routing UI and overlays for UMP streams.
- CI GPU-less testing via Xvfb on Linux.

