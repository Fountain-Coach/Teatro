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

As of 2025-08-04 the test suite reports:

- **Regions:** 47.24% (4204 total, 2218 missed)
- **Functions:** 56.07% (2044 total, 898 missed)
- **Lines:** 44.16% (12011 total, 6707 missed)

---
© 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
