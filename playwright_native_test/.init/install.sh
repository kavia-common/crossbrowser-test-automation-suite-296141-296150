#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/crossbrowser-test-automation-suite-296141-296150/playwright_native_test"
cd "$WORKSPACE"
LOG="$WORKSPACE/playwright_install.log"
: > "$LOG"
# Install node deps deterministically
if [ -f package-lock.json ]; then
  npm ci --no-audit --no-fund --silent 2>&1 | tee -a "$LOG" || { echo "ERROR: npm ci failed (see $LOG)" >&2; exit 4; }
else
  npm i --no-audit --no-fund --silent 2>&1 | tee -a "$LOG" || { echo "ERROR: npm install failed (see $LOG)" >&2; exit 5; }
fi
# Determine Playwright version (prefer installed package)
PW_VER=""
if [ -f node_modules/@playwright/test/package.json ]; then
  PW_VER=$(node -p "require('./node_modules/@playwright/test/package.json').version")
elif [ -f package.json ]; then
  PW_VER=$(node -p "(require('./package.json').devDependencies && require('./package.json').devDependencies['@playwright/test']) || ''")
fi
[ -z "${PW_VER:-}" ] && PW_VER="latest"
PW_BIN_LOCAL="$WORKSPACE/node_modules/.bin/playwright"
# Install Chromium with deps using local binary when possible
if [ -x "$PW_BIN_LOCAL" ]; then
  "$PW_BIN_LOCAL" install --with-deps chromium 2>&1 | tee -a "$LOG" || { echo "ERROR: local playwright installer failed (see $LOG)" >&2; exit 6; }
else
  # Use npx with explicit version and --with-deps
  if command -v npx >/dev/null 2>&1; then
    npx "playwright@${PW_VER}" install --with-deps chromium 2>&1 | tee -a "$LOG" || {
      echo "installer failed; attempting apt fallback and retry" >&2
      sudo apt-get update -q && sudo apt-get install -qy fonts-liberation ca-certificates libnss3 libx11-6 libxcomposite1 libxcursor1 libxrandr2 libxi6 libatk-1.0-0 libatk-bridge2.0-0 libpangocairo-1.0-0 libxinerama1 libgbm1 libasound2 libxss1 libxshmfence1 libglib2.0-0 >/dev/null
      npx "playwright@${PW_VER}" install chromium 2>&1 | tee -a "$LOG" || { echo "ERROR: playwright install failed after fallback (see $LOG)" >&2; exit 7; }
    }
  else
    echo "ERROR: npx not found; cannot install Playwright (see $LOG)" >&2; exit 10
  fi
fi
# Validate browser artifacts and CLI
CACHE_DIR="$WORKSPACE/node_modules/.cache/ms-playwright"
if [ -d "$CACHE_DIR" ] && find "$CACHE_DIR" -maxdepth 3 -type d -name 'chromium*' | grep -q .; then
  echo "OK: chromium artifacts present in $CACHE_DIR" | tee -a "$LOG"
else
  if [ -x "$PW_BIN_LOCAL" ]; then
    "$PW_BIN_LOCAL" show-deps 2>&1 | tee -a "$LOG" | grep -qi chromium && echo "OK: show-deps lists chromium" | tee -a "$LOG" || { echo "ERROR: Chromium not found after install (see $LOG)" >&2; exit 8; }
  else
    echo "ERROR: Chromium artifacts not found and local playwright binary missing (see $LOG)" >&2; exit 9
  fi
fi
# Ensure local binary is executable
if [ ! -x "$PW_BIN_LOCAL" ]; then
  echo "WARN: local playwright binary not executable: $PW_BIN_LOCAL" | tee -a "$LOG" >&2
fi
echo "Installer log: $LOG"
