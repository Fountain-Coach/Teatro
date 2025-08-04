## 4. CLI Integration
_Command-line tools for scripted rendering._

The Teatro view engine exposes an ArgumentParser-powered command-line interface (`RenderCLI`) capable of rendering any `Renderable` to multiple backends.

### Flags

- `--input <file>` or positional file argument
- `--format <target>` where target ∈ {html, svg, png, markdown, codex, svgAnimated, csound, ump}
- `--output <path>` to override the destination filename
- `--watch` to re-render on file changes
- `--width` / `--height` to override canvas dimensions
- `--help` / `--version`

### Defaults

- Omitting `--format` selects `codex` when writing to stdout and `png` when writing to a file.
- When `--output` is absent, defaults such as `output.png`, `output.svg`, or `output.csd` are used.
- Size flags take precedence over environment variables `TEATRO_SVG_WIDTH`, `TEATRO_SVG_HEIGHT`, `TEATRO_IMAGE_WIDTH`, and `TEATRO_IMAGE_HEIGHT`.

### Examples

```bash
swift run RenderCLI --input scene.fountain --format html
swift run RenderCLI score.ly --format svg --output score.svg
swift run RenderCLI --input demo.storyboard --format svgAnimated --output anim.svg
swift run RenderCLI --input scene.fountain --watch --format codex
```

---
© 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.

