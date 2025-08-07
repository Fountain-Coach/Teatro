# 🧠 Repository Agent Manifest

## Status Report

### 1. Supported Input Formats or Interfaces
- CLI accepts `.fountain`, `.ly`, `.mid/.midi`, `.ump`, `.csd`, `.storyboard`, and `.session` files.

### 2. Output Renderers or Transformations
- Renderers available: HTML, Markdown, PNG (with SVG fallback), SVG, animated SVG, Codex previewer, Csound (`.csd`), and Universal MIDI Packet.

### 3. CLI or API Entrypoints
- `RenderCLI` (
  `Sources/CLI/RenderCLI.swift`) exposes command line flags for input, format, output, watching, and size overrides.
- `openapi.yaml` documents an HTTP façade for the CLI at `/render`.

### 4. Existing Test Coverage
- `swift test` runs **187 tests** with no failures.
- Line coverage is **54.26%** as of 2025-08-07.

### 5. Documented Specs vs Implemented Code
- Docs under `Docs/Chapters` describe core protocols, view types, rendering backends, CLI integration, animation system, and more.
- `openapi.yaml` and `Docs/CLI/RenderCLI.md` specify CLI behaviour; CI verifies docs match implementation.

### 6. Linter and CI Presence
- `.swiftlint.yml` configures SwiftLint for sources and tests.
- GitHub Actions workflow `ci.yml` runs SwiftLint, tests, doc generation, and OpenAPI validation.

### 7. Known Gaps or TODOs
- Several deprecated APIs (`Process.launchPath`, `String(contentsOf:)`) trigger warnings.
- Moderate test coverage leaves some modules under-tested.
- Potential drift between CLI docs and OpenAPI spec requires ongoing verification.

## Task Matrix

| Feature | File(s) or Area | Action | Status | Blockers | Tags |
|--------|-----------------|--------|--------|----------|------|
| Replace deprecated `Process.launchPath` | Sources/ViewCore/LilyScore.swift | Switch to `executableURL` and update process launch | ⏳ | None | cli, refactor |
| Update deprecated file-loading calls | Sources/Audio/CsoundSampler.swift; Tests/* | Use `String(contentsOf:encoding:)` across codebase | ⏳ | None | refactor, test |
| Increase renderer test coverage | Tests/RendererTests.swift and related | Add cases for HTML/Markdown and image rendering | ⏳ | Need sample fixtures | renderer, test |
| Sync CLI docs with current flags | Docs/Chapters/04_CLIIntegration.md; Sources/CLI/RenderCLI.swift | Ensure documentation matches implemented options | ⚠️ | Manual verification | docs, cli |
| Automate coverage report updates | COVERAGE.md; scripts | Add script/CI step to refresh coverage metrics | ❌ | Decide tooling | ci, coverage |
