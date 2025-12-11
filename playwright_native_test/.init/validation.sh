#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/crossbrowser-test-automation-suite-296141-296150/playwright_native_test"
cd "$WORKSPACE"
SUMMARY="$WORKSPACE/validation_summary.txt"
# lifecycle notes
echo "BUILD: N/A (test-only project)" >"$SUMMARY"
echo "START: N/A (no long-running service required)" >>"$SUMMARY"
# Run tests and capture outcome
export CI=true
export DISPLAY=${DISPLAY:-:99}
PW_BIN_LOCAL="$WORKSPACE/node_modules/.bin/playwright"
TEST_EXIT=0
if [ -x "$PW_BIN_LOCAL" ]; then
  "$PW_BIN_LOCAL" test --reporter=dot --workers=1 || TEST_EXIT=$?
else
  npx playwright test --reporter=dot --workers=1 || TEST_EXIT=$?
fi
if [ "$TEST_EXIT" -eq 0 ]; then
  echo "TEST: PASS" >>"$SUMMARY"
else
  echo "TEST: FAIL (exit=$TEST_EXIT)" >>"$SUMMARY"
fi
# STOP guidance
echo "STOP: N/A (if ephemeral services were started, they would be stopped via kill or pm2/pmctl)" >>"$SUMMARY"
# Evidence: package.json, playwright version, show-deps, installer log
echo "FILES: $(ls -la "$WORKSPACE"/package.json 2>/dev/null || true)" >>"$SUMMARY"
node -e "try{console.log('playwright package:', require('./node_modules/@playwright/test/package.json').version)}catch(e){console.log('playwright package: not installed') }" >>"$SUMMARY" 2>/dev/null || true
if [ -x "$PW_BIN_LOCAL" ]; then
  # append show-deps output to summary but avoid aborting on error
  "$PW_BIN_LOCAL" show-deps 2>>"$SUMMARY" || true
fi
echo "Installer log path: $WORKSPACE/playwright_install.log" >>"$SUMMARY"
echo "VALIDATION: done; summary at $SUMMARY"
