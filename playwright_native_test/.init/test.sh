#!/usr/bin/env bash
set -euo pipefail
# Run deterministic Playwright sample test headlessly (single worker, CI env local)
WORKSPACE="/home/kavia/workspace/code-generation/crossbrowser-test-automation-suite-296141-296150/playwright_native_test"
cd "$WORKSPACE"
export CI=true
export DISPLAY=${DISPLAY:-:99}
PW_BIN_LOCAL="$WORKSPACE/node_modules/.bin/playwright"
# Prefer local binary to avoid npx inconsistencies
if [ -x "$PW_BIN_LOCAL" ]; then
  "$PW_BIN_LOCAL" test --reporter=list --workers=1 || { echo "ERROR: tests failed" >&2; exit 8; }
else
  # Fallback to npx (may fetch if required)
  npx playwright test --reporter=list --workers=1 || { echo "ERROR: tests failed (npx)" >&2; exit 9; }
fi
