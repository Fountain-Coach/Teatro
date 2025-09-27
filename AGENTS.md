# AGENTS.md Specification: GUI + MIDI2 Integration

(The following is a concrete AGENTS.md-style specification to guide and govern the development and maintenance of the SDL3 GUI integration with MIDI2 in Teatro.)

⸻

## Teatro GUI + MIDI2 Integration Agent (AGENTS.md)

- Owner: Contexter@Fountain-Coach
- Version: 0.1 (2025-09-26, Europe/Berlin)
- Scope:
  - Evolve Teatro into a cross-platform interactive GUI engine using SDL3 for rendering/input and integrating MIDI 2.0 (UMP) streams for real-time visualization and control.
  - Deliver an interactive preview window for FountainAI scripts and storyboards that displays live-rendered content, plays timeline MIDI events, and allows user interaction (playback, scrubbing, MIDI rou[...]
- id: teatro-gui-midi2
- name: Teatro GUI & MIDI2 Interactive Preview

## 1. Description

Introduces an SDL3-powered GUI backend in Teatro and integrates the MIDI2 library for real-time MIDI 2.0 support.

Provides a cross-platform windowing system and rendering loop for Teatro’s outputs, with live visualization of UMP streams (e.g., storyboard timelines, SSE token streams) and interactive controls to[...]

Maintains backward compatibility (no changes to existing SVG/Markdown outputs) and adheres to FountainAI’s deterministic rendering and testing standards.

⸻

### Entrypoint

- type: process
- command:

```bash
swift test && swift run TeatroPreviewDemo
```

Run tests and a demo preview as a basic usage check.

⸻

## APIs

- id: teatro-render-api
  - path: Docs/RenderAPI.md
  - description: Public rendering API extended with live preview capabilities (non-breaking additions)
- id: midi2-core
  - path: midi2 GitHub Repo
  - description: MIDI 2.0 Swift library used for UMP encoding/decoding and device I/O (CoreMIDI on macOS)

⸻

## Policies

- Preserve deterministic, headless outputs: interactive mode must not alter existing render outputs or logic.
- Encapsulate SDL3 usage behind internal APIs; do not expose SDL types to public interfaces.
- Maintain cross-platform compatibility (macOS/Linux minimum; no hardcoded Apple-only code in core paths).
- Ensure memory and thread safety (no leaks, no data races; pair every SDL allocation with a free; run SDL on one thread).
- Incremental development with feature flags and thorough testing at each milestone (no big bang merge).
- Extensive documentation and example usage for all new features; update user guides and README.
- Automated testing for new components where possible (dummy drivers, virtual displays for GUI tests in CI).
- No degradation in performance for non-GUI use; optimize GUI rendering to meet 60 FPS for typical content.

⸻

## Architectural Objectives

### 1. Unified GUI Backend
Implement a Swift-native SDL3 backend for Teatro, enabling window creation, GPU-accelerated drawing, and input handling in a platform-independent way.
This should operate as a module that Teatro’s core can call into, preserving platform-neutral design. SDL integration should allow both onscreen and offscreen (headless) rendering using the same cod[...]

### 2. Interactive Rendering Loop
Establish a robust rendering loop that drives Teatro’s output to the screen in real time. Use SDL’s event polling and timing functions to tick at ~60 FPS. Synchronize with Teatro’s state updates[...]

### 3. MIDI 2.0 Data Pipeline
Integrate the MIDI2 library to receive, decode, visualize, and emit UMP streams in real time. Support common message types (Note On/Off, CC, Program Change, Channel Voice, JR Timestamp). Render visual[...]

### 4. Interactive Controls & Playback
Provide GUI elements for playback control and scrubbing. Interactions map to UMP emissions. Example: play triggers Note On events; scrubbing adjusts timestamps. Map UI controls (sliders, knobs, keybin[...]

### 5. Device & Routing Management
Implement a configuration panel or overlay for MIDI devices. Allow device selection, mapping of CC numbers to UI elements, and persistent settings. Handle disconnect/reconnect gracefully.

### 6. Non-Disruptive Integration
Introduce GUI/MIDI functionality without breaking existing APIs. Maintain headless workflows and deterministic tests.

### 7. Performance & Responsiveness
Target 60 FPS rendering. Ensure real-time MIDI event processing and prompt rendering. Profile, batch draws, and optimize GPU usage.

### 8. Extensibility & Modularity
Encapsulate SDL specifics in a backend module (Sources/TeatroSDLBackend). Keep clear interfaces for core, GUI, and MIDI layers to allow future extensions.

⸻

## 2. Deliverables (PR-ready)

### Code Modules

- Sources/TeatroSDLBackend/ – SDL wrapper module
- SDLWindow.swift
- SDLRenderer.swift
- SDLEvent.swift
- SDLRunLoop.swift
- Platform-specific helpers (if needed)
- Sources/Teatro/Core/TeatroPlayer.swift – orchestration of playback, scene updates, MIDI sync.
- Sources/TeatroRenderAPI/ – expose new functionality (e.g. launchPreview(...), TeatroPreviewController).
- Sources/FountainCLI/TeatroPreviewCommand.swift – CLI command teatro preview &lt;script.fountain&gt;.
- Sources/MIDIIntegration/ – MIDI bridging utilities
- MIDIOutput.swift
- MIDIEndpointManager.swift
- Conversion logic (timeline events → UMP).

### Visual Components

- Sources/TeatroSDLBackend/Overlay/ (optional)
- MIDIOverlay.swift (decoded MIDI visualization)
- TokenStreamView.swift (SSE token streaming visualization)
- Simple SDL-drawn config UI (menu bar, legends).

### Testing

- Tests/TeatroSDLBackendTests.swift
- Unit tests (window lifecycle, events, render loop).
- Offscreen rendering snapshot tests.
- Integration tests for preview lifecycle (start, run, exit).
- CI setup for SDL (Xvfb on Linux).

⸻

## 3. Quality, Docs, and Release Criteria

### 1. Testing & Quality Gates

- Comprehensive unit and integration tests.
- Snapshot tests for deterministic outputs.
- Manual GUI/headless testing on macOS & Linux.
- CI with sanitizers enabled.

### 2. Documentation & Examples

- Update README.md with GUI features.
- Add Docs/Chapters/TeatroInteractiveGUI.md.
- Provide demo (teatro preview) for MIDI-connected workflows.
- Document architecture and SDL backend interfaces.
- Indicate maturity level (beta/experimental if needed).
