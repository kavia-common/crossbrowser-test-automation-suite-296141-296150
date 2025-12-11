#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/crossbrowser-test-automation-suite-296141-296150/playwright_native_test"
cd "$WORKSPACE"
PW_VERSION="${PW_VERSION:-latest}"
# Create package.json if missing (do not set an empty 'type' field)
if [ ! -f package.json ]; then
  cat > package.json <<JSON
{
  "name": "playwright_native_test",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "test": "playwright test",
    "test:ci": "PLAYWRIGHT_HEADLESS=1 node --max-old-space-size=1024 ./node_modules/.bin/playwright test --workers=1 --retries=1"
  },
  "devDependencies": {
    "@playwright/test": "${PW_VERSION}",
    "playwright": "${PW_VERSION}"
  }
}
JSON
fi
# Ensure tests dir exists
mkdir -p "$WORKSPACE/tests"
# Detect module type from package.json; default to cjs
MODULE_TYPE="cjs"
if command -v node >/dev/null 2>&1; then
  TYPE_FIELD=$(node -e "try{const p=require('./package.json'); console.log(p.type||'');}catch(e){console.log('');}") || true
  if [ "$TYPE_FIELD" = "module" ]; then MODULE_TYPE="esm"; fi
fi
# Write Playwright config matching module type
if [ "$MODULE_TYPE" = "esm" ]; then
  cat > "$WORKSPACE/playwright.config.mjs" <<'MJS'
import { defineConfig } from '@playwright/test';
export default defineConfig({
  use: { headless: true, launchOptions: { args: ['--no-sandbox'] } },
  retries: 1,
  workers: 1,
  testDir: './tests'
});
MJS
  # Remove CJS config if present to avoid conflicts
  [ -f "$WORKSPACE/playwright.config.js" ] && rm -f "$WORKSPACE/playwright.config.js"
else
  cat > "$WORKSPACE/playwright.config.js" <<'JS'
/** @type {import('@playwright/test').PlaywrightTestConfig} */
module.exports = {
  use: { headless: true, launchOptions: { args: ['--no-sandbox'] } },
  retries: 1,
  workers: 1,
  testDir: './tests'
};
JS
  [ -f "$WORKSPACE/playwright.config.mjs" ] && rm -f "$WORKSPACE/playwright.config.mjs"
fi
# Generate package-lock if npm available (non-fatal)
if command -v npm >/dev/null 2>&1 && [ -f package.json ]; then
  npm i --package-lock-only > "$WORKSPACE/package_lock_generate.log" 2>&1 || true
fi
# Finished
