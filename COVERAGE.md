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

- **Regions:** 20.53% (5504 total, 4374 missed)
- **Functions:** 22.77% (2784 total, 2150 missed)
- **Lines:** 21.13% (14826 total, 11694 missed)

---
© 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
