# Coverage Report

This document tracks test coverage for the Teatro project. It is updated as the project evolves.

## Generating Coverage

Run the tests with coverage enabled:

```bash
swift test --enable-code-coverage
```

Then generate a human-readable report (example using llvm-cov):

```bash
llvm-cov show .build/debug/TeatroPackageTests.xctest/Contents/MacOS/TeatroPackageTests -instr-profile=.build/debug/codecov/default.profdata > Coverage.txt
```

## Current Summary

Coverage metrics have not yet been collected. Integrate coverage generation into CI to populate this section.

---
© 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
