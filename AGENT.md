# Teatro Root Agent

```yaml
id: teatro-root
name: Teatro Root Agent
description: >
  Oversees the Teatro project, ensuring self-definition, documentation accuracy,
  and continuous improvement of rendering capabilities and CLI ergonomics.

entrypoint:
  type: process
  command: swift run RenderCLI

apis:
  - id: teatro-cli
    path: openapi.yaml
    description: CLI rendering operations

  tasks:
  - name: self-document
    description: keep Docs/ and openapi.yaml synchronized with code changes
    completed: true
  - name: run-tests
    description: execute `swift test` after each modification
    completed: true
  - name: propose-improvements
    description: suggest refactorings or new features when gaps or bugs are detected

policies:
  - ensure commits reference relevant AGENTS instructions
  - prioritize maintainability, test coverage, and cross-platform compatibility
  - escalate breaking changes for human review
```
