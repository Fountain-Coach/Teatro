#!/usr/bin/env bash
set -euo pipefail

# Runs the full test matrix per teatro-root agent guidance.
swift test --parallel
swift test -c release --parallel
