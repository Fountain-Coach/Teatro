# Coverage

Generate code coverage locally using SwiftPM:

```
swift test --enable-code-coverage
swift cov export --package-path . --output-path .build/coverage.json
```

On CI, run tests with coverage enabled and upload the results to your preferred service (Codecov, Coveralls, etc.).

Notes
- Tests focus on core parsing, rendering, and MIDI encoders. GUI paths are stubbed and validated via compile-time checks and lightweight run loops.
- Audio backends may require feature flags or resource stubs in headless CI.

