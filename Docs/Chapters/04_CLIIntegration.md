## 4. CLI Integration
_Command-line tools for scripted rendering._

The Teatro view engine exposes an ArgumentParser-powered command-line interface (`RenderCLI`) capable of rendering any `Renderable` to multiple backends.

The executable entry point lives in [`Sources/CLI/main.swift`](../../Sources/CLI/main.swift) and invokes `RenderCLI.main()`. Output generators are defined by the `RenderTarget` enumeration in [`Sources/CLI/RenderCLI.swift`](../../Sources/CLI/RenderCLI.swift).

### Flags

- `--input <file>` or positional file argument
- `--format <target>` where target ∈ {html, svg, png, markdown, codex, svgAnimated, csound, ump}
- `--output <path>` to override the destination filename
- `--force-format` to override output extension mismatches
- `--watch` to re-render on file changes
- `--width` / `--height` to override canvas dimensions
- `--help` / `--version`

### Defaults

- When `--output` is present but `--format` is omitted, the extension of the output path selects the format; otherwise `codex` (stdout) or `png` (file) is used.
- When `--output` is absent, defaults such as `output.png`, `output.svg`, or `output.csd` are used.
- If `--width`/`--height` are omitted, the CLI reads `TEATRO_WIDTH` and `TEATRO_HEIGHT` and propagates them to `TEATRO_SVG_WIDTH`, `TEATRO_SVG_HEIGHT`, `TEATRO_IMAGE_WIDTH`, and `TEATRO_IMAGE_HEIGHT`.

### Examples

```bash
swift run RenderCLI --input scene.fountain --format html
swift run RenderCLI score.ly --format svg --output score.svg
swift run RenderCLI --input demo.storyboard --format svgAnimated --output anim.svg
swift run RenderCLI --input scene.fountain --watch --format codex
```

---
© 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.

