# Teatro — GUI Render API Blueprint & PR Checklist (for FountainAI Integrations)

**Status:** Proposal ready for PR  
**Audience:** Teatro maintainers and contributors  
**Scope:** Add a stable, embeddable Render API and small SwiftUI preview hooks so external services (e.g., `codex-deployer`) can use Teatro as the exclusive GUI provider in both headless and desktop flows.

---

## 1) Goals & Non‑Goals

### Goals
- Provide a minimal **public Render API** to convert domain inputs into viewable/exportable artifacts:
  - `.fountain` → SVG (+ optional Markdown synopsis)
  - `.ump` / Storyboard DSL → animated SVG + re‑emitted `.ump` (+ optional `.mid` legacy export)
  - `.session|.log|.md` → Markdown reflection + overlay marks
  - Lightweight list/search rendering → Markdown and/or small SVG panels
- Keep **Teatro as the only renderer**: no other GUI engines or renderers in downstream repos.
- Support **headless** (Linux) and **desktop** (macOS) usage through the same Render API.
- Offer an **embeddable SwiftUI preview view** (`TeatroPlayerView`) that accepts SVG (and later timeline data).
- Expose **SSE-over-MIDI2 streams** with timing and reliability overlays in the preview player.

### Non‑Goals
- Building product‑specific UIs; Teatro stays a rendering/runtime engine.
- Adding network clients; downstream apps handle HTTP and persistence.
- Owning orchestration or deployment; that remains in `codex-deployer`.

---

## 2) Public Module: `TeatroRenderAPI`

Add a new public SPM target inside the Teatro repo that provides stable, source‑based entrypoints required by external callers.

### 2.1 Module layout

```
Sources/
  Teatro/                    # existing engine
  TeatroRenderAPI/           # NEW - stable adapters + types
    RenderAPI.swift
    Inputs.swift
    Errors.swift
    SwiftUI+Preview.swift    # optional preview helper (macOS)
Tests/
  TeatroRenderAPITests/      # NEW - API & snapshot tests
```

### 2.2 Public Types (initial surface)

```swift
// Sources/TeatroRenderAPI/RenderAPI.swift

import Foundation

public struct RenderResult {
    public let svg: Data?
    public let markdown: String?
    public let ump: Data?

    public init(svg: Data? = nil, markdown: String? = nil, ump: Data? = nil) {
        self.svg = svg
        self.markdown = markdown
        self.ump = ump
    }
}

public enum RenderError: Error, CustomStringConvertible {
    case parse(String)
    case layout(String)
    case io(String)
    case unsupported(String)

    public var description: String {
        switch self {
        case .parse(let m): return "Parse error: \(m)"
        case .layout(let m): return "Layout error: \(m)"
        case .io(let m): return "I/O error: \(m)"
        case .unsupported(let m): return "Unsupported: \(m)"
        }
    }
}
```

```swift
// Sources/TeatroRenderAPI/Inputs.swift

import Foundation

public protocol RenderScriptInput { var fountainText: String { get } }
public protocol RenderStoryboardInput {
    var umpData: Data? { get }
    var storyboardDSL: String? { get }
}
public protocol RenderSessionInput { var logText: String { get } }
public protocol RenderSearchInput { var query: String { get } }

public struct SimpleScriptInput: RenderScriptInput { public let fountainText: String; public init(fountainText: String){ self.fountainText = fountainText } }
public struct SimpleStoryboardInput: RenderStoryboardInput {
    public let umpData: Data?
    public let storyboardDSL: String?
    public init(umpData: Data? = nil, storyboardDSL: String? = nil) { self.umpData = umpData; self.storyboardDSL = storyboardDSL }
}
public struct SimpleSessionInput: RenderSessionInput { public let logText: String; public init(logText: String){ self.logText = logText } }
public struct SimpleSearchInput: RenderSearchInput { public let query: String; public init(query: String){ self.query = query } }
```

```swift
// Sources/TeatroRenderAPI/RenderAPI.swift (continued)

public enum TeatroRenderer {
    /// .fountain -> SVG (+ optional Markdown synopsis)
    public static func renderScript(_ input: RenderScriptInput) throws -> RenderResult {
        // 1) Parse Fountain
        // 2) Layout to SVG
        // 3) Produce optional synopsis Markdown
        // return RenderResult(svg: svgData, markdown: synopsis)
        throw RenderError.unsupported("stub")
    }

    /// .ump / storyboard DSL -> animated SVG + (re)emitted .ump
    /// optional: MIDI 1.0 export handled by core engine (out of scope here)
    public static func renderStoryboard(_ input: RenderStoryboardInput) throws -> RenderResult {
        // 1) Parse UMP or storyboard DSL
        // 2) Timeline -> animated SVG
        // 3) Emit normalized UMP
        throw RenderError.unsupported("stub")
    }

    /// .session|.log|.md -> Markdown reflection + overlay marks
    public static func renderSession(_ input: RenderSessionInput) throws -> RenderResult {
        // 1) Parse text
        // 2) Build reflection markdown
        // 3) Optionally embed overlay markers (JSON in fenced block)
        throw RenderError.unsupported("stub")
    }

    /// Lightweight list/search rendering (Plan/Checklist panes)
    public static func renderSearchResults(_ input: RenderSearchInput) throws -> RenderResult {
        // 1) Format markdown list
        throw RenderError.unsupported("stub")
    }
}
```

### 2.3 SwiftUI Preview Hook (macOS)

```swift
// Sources/TeatroRenderAPI/SwiftUI+Preview.swift

#if canImport(SwiftUI)
import SwiftUI

/// Basic preview surface that can render an SVG blob produced by TeatroRenderer.
public struct TeatroPlayerView: View {
    public let svgData: Data?

    public init(svgData: Data?) {
        self.svgData = svgData
    }

    public var body: some View {
        Group {
            if let svgData {
                // Replace with actual SVG rendering (e.g., using a vector layer or WebView)
                Text("SVG bytes: \(svgData.count)")
                    .font(.footnote.monospaced())
            } else {
                Text("No SVG loaded")
            }
        }.frame(minWidth: 320, minHeight: 240)
    }
}
#endif
```

> Note: The above view is intentionally minimal; the actual SVG/timeline playback should bind into Teatro’s internal player/renderer when wired in this module or by exposing a dedicated `TeatroPlayerView` from core.

---

## 3) SPM Wiring

Update `Package.swift` to **produce** `TeatroRenderAPI` as a public product:

```swift
.products += [
    .library(name: "TeatroRenderAPI", targets: ["TeatroRenderAPI"])
]

.targets += [
    .target(name: "TeatroRenderAPI", dependencies: ["Teatro"]),
    .testTarget(name: "TeatroRenderAPITests", dependencies: ["TeatroRenderAPI"])
]
```

---

## 4) Tests

- **Snapshot tests** for SVG and Markdown outputs (git‑tracked golden files).
- **API conformance tests** asserting public type names and method signatures.
- **UMP round‑trip tests**: UMP → normalized UMP (expect stable serialization).
- **Threading**: verify render calls are thread‑safe or document constraints.
- **macOS only**: smoke test that `TeatroPlayerView` instantiates in a Preview.

Directory:
```
Tests/TeatroRenderAPITests/
  ScriptRenderingTests.swift
  StoryboardRenderingTests.swift
  SessionRenderingTests.swift
  APIConformanceTests.swift
  __snapshots__/
```

---

## 5) Versioning & Docs

- **SemVer**: bump **minor** (new public module).
- Add `Docs/RenderAPI.md` with examples.
- Update README to mention the new module and the `TeatroPlayerView` hook.

---

## 6) Security & Perf Notes

- No network calls; deterministic renders.
- Large inputs: document recommended limits; stream parse where possible.
- Avoid leaking system fonts; use embedded or documented fallbacks.

---

## 7) PR Checklist (Teatro)

**Branch**: `feat/render-api`  
**PR Title**: `feat: add TeatroRenderAPI (public render entrypoints + SwiftUI preview hook)`

- [ ] Create target `TeatroRenderAPI` with public API surface above.
- [ ] Implement Fountain → SVG (+synopsis) pipeline.
- [ ] Implement UMP/Storyboard → animated SVG + normalized UMP.
- [ ] Implement Session → Markdown (+overlay markers) renderer.
- [ ] Implement lightweight Search/Plan → Markdown renderer.
- [ ] Add `TeatroPlayerView` (macOS) hook for SVG/timeline preview.
- [ ] Wire `Package.swift` products & targets.
- [ ] Add snapshot tests and API conformance tests.
- [ ] Add `Docs/RenderAPI.md` and README section.
- [ ] Document SSE-over-MIDI2 streaming and include demo capture.
- [ ] Bump version (minor) and update CHANGELOG.
- [ ] CI green on macOS + Linux.
- [ ] Tag release `vX.Y.0`.

**Acceptance Criteria**
- Public types & functions match signatures listed above.
- Renderers produce deterministic outputs for test fixtures.
- `TeatroPlayerView` compiles and displays a non‑empty SVG as a smoke test.

**Rollback Plan**
- Revert PR; keep module code behind a feature branch.
- No migration required (pure additive).

---

## 8) Codex Action Block

Place the following in `agent.md` (or keep in this file) so Codex can act:

```yaml
codex:
  intent: "Introduce a public Render API in Teatro for downstream GUI integration"
  branch: "feat/render-api"
  tasks:
    - path: "Package.swift"
      action: "edit"
      description: "Add products and targets for TeatroRenderAPI and tests"
    - path: "Sources/TeatroRenderAPI/RenderAPI.swift"
      action: "create"
      contents: "<paste from section 2.2>"
    - path: "Sources/TeatroRenderAPI/Inputs.swift"
      action: "create"
      contents: "<paste from section 2.2>"
    - path: "Sources/TeatroRenderAPI/SwiftUI+Preview.swift"
      action: "create"
      contents: "<paste from section 2.3>"
    - path: "Tests/TeatroRenderAPITests/ScriptRenderingTests.swift"
      action: "create"
      contents: "<skeleton with fixture snapshot>"
    - path: "Docs/RenderAPI.md"
      action: "create"
      contents: "<public docs and examples>"
  open_pr:
    title: "feat: add TeatroRenderAPI (public render entrypoints + SwiftUI preview hook)"
    body: "Implements stable render adapters used by codex-deployer. Adds tests and docs."
    reviewers: ["Fountain-Coach/teatro-maintainers"]
    labels: ["feature", "rendering", "public-api"]
```

---

## 9) Appendix — Example Fixtures

- `Fixtures/Script/scene.fountain` → `__snapshots__/scene.svg`, `scene.md`
- `Fixtures/Storyboard/timeline.ump` → `__snapshots__/timeline.svg`, `timeline.ump`
- `Fixtures/Session/conversation.log` → `__snapshots__/session.md`
