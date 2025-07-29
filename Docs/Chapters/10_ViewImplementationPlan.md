## 10. View Implementation and Testing Plan

This document outlines how to implement the Teatro view system and how each view should be unit tested. The plan follows the structures defined in the existing documentation and assumes that the Swift package layout remains consistent with the **Summary** guide.

### 10.1 Core Protocols
Implement the protocols under `Sources/ViewCore`:

- **Renderable** – exposes `render() -> String`.
- **Layouting** – extends `Renderable` with alignment and padding properties.
- **Alignment** – enum describing `.leading`, `.center`, `.trailing`.
- **TextStyle** – enum with `.bold`, `.italic`, `.underline`, `.plain` plus `apply(to:)`.
- **ViewBuilder** – result builder returning `[Renderable]`.

Tests should verify protocol conformance for all view types and confirm that `TextStyle.apply` returns the expected string for each case.

### 10.2 Basic View Types
Implement the primary views from `Docs/ViewTypes` in `Sources/ViewCore`:

1. **Text** – renders styled text via `TextStyle.apply`.
2. **VStack** – vertically stacks child views with padding and alignment.
3. **HStack** – horizontally stacks child views with padding.
4. **Stage** – top-level container that prepends a title.
5. **TeatroIcon** – renders a symbolic icon with the `◉` prefix.

Testing strategy:
- Unit tests should instantiate each view with sample data and verify the exact string returned by `render()`.
- For `VStack` and `HStack`, include tests with multiple child views and custom padding to ensure indentation and spacing rules.

### 10.3 Specialized Views
Additional renderable components appear in other documentation sections:

- **LilyScore** (`Docs/LilyPondMusicRendering`) – simple wrapper that renders its content string and provides a `renderToPDF` helper. Unit tests should verify the plain `render()` output. PDF generation can be tested with a temporary directory and checking that files are created.
- **FountainElement** and **FountainSceneView** (`Docs/FountainScreenplayEngine`) – parse Fountain text into elements and render each one. Tests should parse a short script and validate the resulting array of `FountainElement` cases as well as the final rendered string.

### 10.4 Renderers and CLI
Although not strictly views, renderers are important for integration testing:

- Implement `HTMLRenderer`, `SVGRenderer`, `ImageRenderer`, `MarkdownRenderer`, and `CodexPreviewer` under `Sources/Renderers` exactly as shown in the docs.
- Implement `RenderCLI` in `Sources/CLI` to wire up the renderers. Use `swift run` in tests to ensure the binary can be invoked with different targets.
- `SVGAnimator` should be tested with sample `Storyboard`.
- Include `svg-animated` as a CLI output target in integration tests.

### 10.5 Animation System
Implement `Animator` under `Sources/Renderers` or a dedicated `Sources/Animation` folder. Tests should create a series of views, call `Animator.renderFrames`, and confirm that the expected `.png` files appear in `Animations/`.
"TeatroPlayerView" should be implemented under `TeatroPlaygroundUI`. It must
sync `Storyboard` rendering with `MIDISequence` timing and include
play/pause/reset controls plus support for semantic overlays.

### 10.6 Test Organization
Create test files in `Tests/` following SwiftPM conventions:

- `ViewCoreTests.swift` – covers protocols and basic view types.
- `MusicViewTests.swift` – tests `LilyScore` behaviour.
- `FountainViewTests.swift` – tests screenplay parsing and rendering.
- `RendererTests.swift` – verifies HTML/SVG output strings and image file creation (Cairo can be mocked if unavailable).
- `RendererTests.swift` should include a test for `<g id="scene0">` and `<animate>` detection.
- `CLITests.swift` – uses `Process` to run the CLI with different arguments and checks the output or generated files.

Add runtime animation tests if needed—for example a smoke test that switches
`TeatroPlayerView` scenes. Integration tests should cover MIDI-driven playback;
unit tests for MIDI audio are not required.

Each test should clean up temporary files after execution to keep the repository tidy.

### 10.7 Continuous Testing
Update `Package.swift` to add library and executable targets for the new sources. Ensure that `swift test` passes locally. Consider adding a simple GitHub Actions workflow later to run `swift build` and `swift test` on push.

---

Following this implementation and testing plan will produce a fully functional Teatro View Engine with deterministic rendering logic and comprehensive unit coverage for every view.

```
© 2025 Contexter alias Benedikt Eickhoff, https://fountain.coach. All rights reserved.
Unauthorized copying or distribution is strictly prohibited.
```



``````text
©\ 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
``````
