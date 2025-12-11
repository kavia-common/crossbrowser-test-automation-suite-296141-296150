#!/usr/bin/env bash
set -euo pipefail
# environment - verify runtimes, install node deps and Playwright browsers (user-writable)
WORKSPACE="/home/kavia/workspace/code-generation/crossbrowser-test-automation-suite-296141-296150/playwright_native_test"
cd "$WORKSPACE"
# Verify node >=18
NODE_BIN=$(command -v node || true)
if [ -z "$NODE_BIN" ]; then echo "ERROR: node not found" >&2; exit 2; fi
NODE_VER=$($NODE_BIN -p "process.versions.node")
MAJOR=$(printf "%s" "$NODE_VER" | cut -d. -f1)
if [ "${MAJOR:-0}" -lt 18 ]; then echo "ERROR: node $NODE_VER found; require >=18" >&2; exit 3; fi
# Choose package manager by lockfile
USE_PKG_MANAGER="npm"
if [ -f yarn.lock ]; then USE_PKG_MANAGER="yarn"; elif [ -f package-lock.json ]; then USE_PKG_MANAGER="npm"; fi
# Prepare workspace-owned Playwright browsers path
PW_BROWSERS_PATH="$WORKSPACE/.playwright-browsers"
mkdir -p "$PW_BROWSERS_PATH"
# Ensure ownership mirrors workspace directory where possible
chown --reference="$WORKSPACE" "$PW_BROWSERS_PATH" 2>/dev/null || true
export PLAYWRIGHT_BROWSERS_PATH="$PW_BROWSERS_PATH"
# Install node deps deterministically with logs
if [ -f package.json ]; then
  if [ "$USE_PKG_MANAGER" = "yarn" ]; then
    yarn install --frozen-lockfile --check-files > "$WORKSPACE/yarn_install.log" 2>&1 || (cat "$WORKSPACE/yarn_install.log" >&2; exit 4)
  else
    if [ -f package-lock.json ]; then
      npm ci --prefer-offline --no-audit --no-fund > "$WORKSPACE/npm_install.log" 2>&1 || (cat "$WORKSPACE/npm_install.log" >&2; exit 5)
    else
      npm i --no-audit --no-fund > "$WORKSPACE/npm_install.log" 2>&1 || (cat "$WORKSPACE/npm_install.log" >&2; exit 6)
    fi
  fi
fi
# Playwright installer log
PW_LOG="$WORKSPACE/playwright_install.log"
: > "$PW_LOG"
# Minimal OS libs required for Playwright browsers (install only if missing)
NEEDED_LIBS=(libnss3 libatk-1.0-0 libxss1 libasound2 libgtk-3-0)
MISSING_LIBS=()
for lib in "${NEEDED_LIBS[@]}"; do dpkg -s "$lib" >/dev/null 2>&1 || MISSING_LIBS+=("$lib"); done
if [ ${#MISSING_LIBS[@]} -gt 0 ]; then
  sudo apt-get update -q >> "$PW_LOG" 2>&1 && sudo apt-get install -y -q "${MISSING_LIBS[@]}" >> "$PW_LOG" 2>&1 || (cat "$PW_LOG" >&2; exit 7)
fi
# Run Playwright installer as unprivileged user, target workspace-owned browsers path
if command -v npx >/dev/null 2>&1; then
  PLAYWRIGHT_BROWSERS_PATH="$PW_BROWSERS_PATH" npx --yes playwright install chromium firefox webkit >> "$PW_LOG" 2>&1 || (cat "$PW_LOG" >&2; exit 8)
else
  echo "ERROR: npx not available" >&2; exit 9
fi
# Verify Playwright CLI and installed browsers
if PLAYWRIGHT_BROWSERS_PATH="$PW_BROWSERS_PATH" npx --yes playwright --version >> "$PW_LOG" 2>&1; then :; else cat "$PW_LOG" >&2; exit 10; fi
if PLAYWRIGHT_BROWSERS_PATH="$PW_BROWSERS_PATH" npx --yes playwright show-browsers --installed >> "$PW_LOG" 2>&1; then :; else cat "$PW_LOG" >&2; exit 11; fi
# Optionally write global profile only when explicitly requested
if [ "${PLAYWRIGHT_WRITE_GLOBAL_PROFILE:-0}" = "1" ]; then
  sudo bash -c 'cat > /etc/profile.d/playwright_env.sh <<"EOF"
# Playwright dev environment defaults (set by setup script)
export NODE_ENV=${PLAYWRIGHT_NODE_ENV:-development}
export PLAYWRIGHT_BROWSERS_PATH="'"$PW_BROWSERS_PATH"'"
EOF'
  sudo chmod 644 /etc/profile.d/playwright_env.sh
fi
# Ensure ownership of created files is current user
chown -R --reference="$WORKSPACE" "$PW_BROWSERS_PATH" 2>/dev/null || true
echo "INSTALL_SUCCESS"
