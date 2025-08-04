## 13. Session Format

_Serialization for captured CLI interactions._

A `.session` file records a sequence of terminal commands and their textual output.  The file is plain UTF-8 text with no additional markup or metadata.  Each line represents exactly what appeared in the terminal during a recording.  Empty lines are preserved to maintain the original spacing.

### Grammar

```ebnf
session   = { line , "\n" } ;
line      = command | output ;
command   = "$" , " " , text ;
output    = text ;
text      = { character - "\n" } ;
```

Each line is interpreted literally; commands begin with a dollar sign and a space, while output lines may contain any text.

### Example
```
$ teatro --format codex sample.storyboard
Rendered storyboard to output.codex
```

### Usage
- **Parsing**: `SessionParser` wraps the raw file contents into a `Session` renderable.
- **Rendering**: The CLI simply echoes the stored text back to stdout or writes it to the requested output path.
- **Extensions**: Future revisions may structure entries as JSON for richer session metadata.

---

©\ 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
