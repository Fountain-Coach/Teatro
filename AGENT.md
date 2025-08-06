# 🤖 Teatro AGENT.md 

> This repository contains the **Teatro View Engine**, a declarative Swift 6 framework for rendering text, music, and screenplay artifacts. Documentation lives under the `Docs/` directory and is organized by feature area.

### Teatro CLI Implementation Rules

This document sets out the guidelines that **Fountain‑Codex**, or any automated agent, **MUST** follow when implementing or evolving the command‑line interface (CLI) for the **Teatro view engine**.

#### COPYRIGHT POLICY 🔐

**Mandatory Action:** We **MUST** ensure that the following footer appears at the end of **every** file (source code, Markdown, config, logs, etc.) it creates or updates or maintains. If absent, append it (preceded by a newline and, for Markdown, an optional horizontal rule `---`) and commit the change.

```text
©\ 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
```

#### Objectives

The CLI must evolve from a static demo into a comprehensive tool that:

- Exposes every Teatro rendering backend
- Supports batch scripting and interactive GUI modes
- Remains simple to use and well‑documented

#### 1. Accept Custom Input

- **Flag**: `--input ` or positional file argument
- **Recognized extensions**:
  - `.fountain` (Fountain screenplay)
  - `.ly`       (LilyPond score)
  - `.mid`/`.midi` (MIDI 1.0 file)
  - `.ump`      (Universal MIDI Packet)
  - `.csd`      (Csound score)
  - `.storyboard` (Storyboard DSL)
  - `.session`  (Session log)
- **Behavior**: Extension→parser/renderer dispatch. Unknown extensions produce an informative error.

#### 2. Select Output Format

- **Supported targets**: `html`, `svg`, `png`, `markdown`, `codex`, `svgAnimated`, `csound`, `ump`
- **Flag**: `--format ` (case‑insensitive)
- **Defaults** when `--format` is omitted:
  - **stdout** → `codex`
  - **file output** → `png`

#### 3. Specify Output File Names

- **Flag**: `--output ` to override destination filename or directory
- **Defaults** if omitted, based on format:
  - `output.png` for PNG
  - `output.svg` for SVG
  - `output.csd` for Csound scores
  - etc.

#### 4. Respect Environment Variables

When determining rendering dimensions, the CLI must apply precedence:

1. **Flags**: `--width`, `--height`
2. **Environment variables**: `TEATRO_SVG_WIDTH`, `TEATRO_SVG_HEIGHT`, `TEATRO_IMAGE_WIDTH`, `TEATRO_IMAGE_HEIGHT`
3. **Built‑in defaults** (per renderer code)

#### 5. Provide Usage & Version

- **Flags**: `--help` and `--version`
- **Help output** must list:
  - Supported input types and formats
  - All flags (`--watch`, size overrides, `--output`)
  - Examples of both batch render and watch mode
- **Automated tests** should validate help/version text against examples
- Unknown flags/targets must exit non‑zero with an error message

#### 6. Maintain Backwards Compatibility & Deprecation

- No input → built‑in demo view for all formats
- Deprecation policy:
  - Announce planned removals in help text and a `CHANGELOG.md`
  - Provide at least **3 months** notice before breaking changes
  - Mark deprecated flags/options with warnings

#### 7. Extensibility

- **Add formats** by extending the `RenderTarget` enum
- **Central format registry**: update a single doc/index of all targets whenever the enum changes
- Update routing logic, docs (`Docs/Chapters/04_CLIIntegration.md`), and tests

#### 8. Testing & Quality

- Tests in `Tests/CLI`
- Use Swift ArgumentParser test helpers: `XCTAssertExit`, `XCTAssertHelp`, `XCTAssertVersion`
- Cover:
  - Argument parsing
  - Watch/dispatch logic
  - Static vs. binary output correctness

#### 9. Live‑Reload Watch Mode

- **Flag**: `--watch`
- Implement with `DispatchSource.makeFileSystemObjectSource` (flags > env > defaults)
- Graceful shutdown on SIGINT (cancel source, close FD)

#### 10. OpenAPI Specification

~~~yaml
openapi: 3.0.3
info:
  title: Teatro CLI API
  description: |
    HTTP façade for the Teatro command‑line interface, exposing all rendering back‑ends and GUI modes.
    Conforms to the Teatro CLI Implementation Rules (agent.md v2025‑08‑03).
  version: '2025.08.03'
  x-deprecation-policy:
    schedule: ">=2 minor releases"
    announcement: "3 months before removal"
servers:
  - url: http://localhost:8000
    description: Local CLI server

paths:
  /cli/version:
    get:
      operationId: getCliVersion
      summary: Get the Teatro CLI version
      responses:
        '200':
          description: Current CLI version
          content:
            application/json:
              schema:
                type: object
                properties:
                  version:
                    type: string
                    example: "1.2.0"

  /cli/help:
    get:
      operationId: getCliHelp
    summary: Display usage and help information
      responses:
        '200':
          description: CLI usage text
          content:
            text/plain:
              schema:
                type: string

  /cli/changelog:
    get:
      operationId: getCliChangelog
      summary: Retrieve the CLI CHANGELOG with deprecation notices
      responses:
        '200':
          description: Changelog entries
          content:
            application/json:
              schema:
                type: array
                items:
                  type: object
                  properties:
                    version:
                      type: string
                    changes:
                      type: string

  /cli/render:
    post:
      operationId: renderTeatro
      summary: Render a Teatro view or user file into the requested format
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              properties:
                inputFile:
                  type: string
                  description: |
                    Path to a user file. Supported extensions:
                    - .fountain (Fountain screenplay)
                    - .ly       (LilyPond score)
                    - .mid/.midi (MIDI 1.0 file)
                    - .ump      (Universal MIDI Packet file)
                    - .csd      (Csound score)
                    - .storyboard (Storyboard DSL)
                    - .session  (Session log)
                format:
                  type: string
                  enum: [ html, svg, png, markdown, codex, svgAnimated, csound, ump ]
                  description: Rendering target format. Defaults:
                    - codex when writing to stdout
                    - png when writing to file
                outputPath:
                  type: string
                  description: Destination path. Overrides defaults such as output.png, output.svg, output.csd.
                watch:
                  type: boolean
                  default: false
                  description: |
                    Watch the input file for changes and re‑render automatically.
                width:
                  type: integer
                  description: |
                    Override TEATRO_SVG_WIDTH / TEATRO_IMAGE_WIDTH.  Precedence: flags > env > defaults.
                height:
                  type: integer
                  description: |
                    Override TEATRO_SVG_HEIGHT / TEATRO_IMAGE_HEIGHT.  Precedence: flags > env > defaults.
              # 'format' is optional; defaults are applied as described
      responses:
        '200':
          description: Rendering results
          content:
            application/json:
              schema:
                type: object
                properties:
                  stdout:
                    type: string
                  files:
                    type: array
                    items:
                      type: string
                  message:
                    type: string

  /cli/gui/{mode}:
    post:
      operationId: launchGuiMode
      summary: Launch a native GUI mode built with Teatro
      parameters:
        - in: path
          name: mode
          schema:
            type: string
            enum: [ script, storyboard, session ]
          required: true
          description: GUI subcommand to launch
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              properties:
                inputFile:
                  type: string
                  description: Path to the mode’s file (.fountain, .storyboard, .ump, .csd, .session)
                watch:
                  type: boolean
                  default: false
                  description: Automatically reload on file changes
                width:
                  type: integer
                  description: Override preview canvas width
                height:
                  type: integer
                  description: Override preview canvas height
              required:
                - inputFile
      responses:
        '200':
          description: GUI launched successfully
          content:
            application/json:
              schema:
                type: object
                properties:
                  message:
                    type: string
~~~

### Contributor Guidelines

- Use the Swift 6.1 toolchain.
- Run `swift build` and `swift test` before committing code.
- Follow the directory conventions described in `Docs/Summary/README.md`.
- Maintain `Docs/ImplementationPlan.md` as the status quo and action planning record, updating it whenever priorities or implementation state change.

### Project Highlights

- Modular `Renderable` protocol with multiple rendering back‑ends.
- Multiple outputs: HTML, Markdown, SVG, PNG, animated SVG, and Codex introspection.
- Music rendering via LilyPond scores, MIDI 2.0 sequencing, and real‑time sampling with Csound/FluidSynth.
- Screenplay and storyboard support using the Fountain format.
- CLI utilities and a SwiftUI preview layer for quick iteration.

For detailed walkthroughs see the individual documentation files linked from the root `README.md`.

## Implementation & Alignment Task Matrix (as of 6 Aug 2025)

The table below summarises outstanding work for the **Fountain‑Coach/Teatro** repository.  Each row is a discrete unit of implementation or alignment work derived from the status report.  Status codes: ✅ = done, ⏳ = todo, ⚠️ = partial, ❌ = missing.

| Feature | File(s) or Area | Action | Status | Blockers | Tags |
|---|---|---|---|---|---|
| **Integrate MIDI parser into CLI** | `Sources/CLI/RenderCLI.swift`, `Sources/Parsers/MidiFileParser.swift` | Connect the existing `MidiFileParser` so that `.mid`/`.midi` files are accepted by the CLI, parsed and rendered.  Update the input detection logic and ensure the resulting output respects `--format` choices. | ⚠️ | None; parser exists but CLI rejects input | parser, cli |
| **Integrate UMP parser into CLI** | `RenderCLI.swift`, `UMPParser.swift` | Enable `.ump` inputs by wiring the `UMPParser` into the CLI.  The CLI should parse UMP files and either render them directly or convert them to human‑readable output. | ⚠️ | None; parser exists but not used | parser, cli |
| **Complete UMP output generation** | `RenderCLI.swift`, `UMPEncoder.swift` | Replace the placeholder dummy note used for `.ump` output with a full implementation that converts parsed MIDI/UMP data into the correct 32‑bit word sequence.  Support user‑provided data rather than a hard‑coded note. | ⚠️ | Requires decisions about input format and semantics | renderer, cli |
| **Implement API façade** | New `Server` module or service | Build an HTTP server that exposes the CLI via the OpenAPI spec defined in `AGENT.md`.  Implement endpoints for `/cli/version`, `/cli/help`, `/cli/changelog`, `/cli/render` and `/cli/gui/{mode}` and mirror CLI behaviour.  Include tests for each endpoint. | ❌ | Requires architectural design and network layer | api, cli |
| **Increase test coverage** | `Tests/` directory | Add tests for watch mode behaviour, environment variable precedence, and output correctness for all renderers.  After MIDI/UMP integration, add tests covering those paths.  Aim to improve line coverage beyond the current 44 %. | ⚠️ | Dependent on implementing MIDI/UMP and other features | test |
| **Document audio back‑ends & update Implementation Plan** | `Docs/ImplementationPlan.md`, `Docs/Chapters/` | Update documentation to reflect the current state of audio back‑ends (e.g., Csound, lilypond).  Ensure the Implementation Plan and task matrix are consistent—mark unimplemented features like MIDI/UMP accordingly and document Csound/LilyPond usage requirements. | ⚠️ | None | docs |
| **Synchronise agent task matrix with code** | `Sources/Parsers/agent.md`, `Docs/ImplementationPlan.md` | Review the existing agent task matrix and mark tasks whose status has changed (e.g., MIDI/UMP integration is incomplete).  Keep this matrix up to date with the implementation state so contributors can rely on a single source of truth. | ⚠️ | None | docs, management |
| **Add linter configuration** | Project root | Introduce a Swift linter (e.g., SwiftLint or SwiftFormat).  Create a configuration file (e.g., `.swiftlint.yml`), integrate it into development workflow and CI, and update contribution guidelines. | ❌ | Must choose a linter and decide on style rules | ci, linter |
| **Set up continuous integration** | `.github/workflows/`, CI scripts | Establish a CI pipeline (GitHub Actions, GitLab CI, etc.) that builds the project, runs tests, checks formatting/linting and reports coverage.  Automate the manual `swift build` and `swift test` steps currently described in the docs. | ❌ | Requires CI configuration and secrets (if needed) | ci |
| **Improve watch mode robustness** | `RenderCLI.swift` | Evaluate and refine the file‑watching implementation across macOS and Linux.  Ensure the fallback timer on Linux reliably detects changes and minimises CPU usage.  Add tests for cross‑platform watch behaviour. | ⚠️ | OS‑dependent behaviour; may need to abstract watchers | cli, test |


```text
©\ 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
```
