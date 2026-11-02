#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
TEST_DIR="${TMPDIR:-/tmp}/trackedge-tests"
mkdir -p "$TEST_DIR/cache"
xcrun swiftc -swift-version 5 -module-cache-path "$TEST_DIR/cache" Sources/Gestures.swift Sources/CursorLock.swift Tests/main.swift -o "$TEST_DIR/tests"
"$TEST_DIR/tests"
