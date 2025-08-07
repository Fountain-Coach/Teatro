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

As of 2025-08-07 the test suite reports:

- **Regions:** 58.36% (5062 total, 2108 missed)
- **Functions:** 66.91% (2602 total, 861 missed)
- **Lines:** 54.26% (13964 total, 6387 missed)

---
© 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
