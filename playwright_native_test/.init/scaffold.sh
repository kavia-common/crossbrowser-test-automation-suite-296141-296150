#!/usr/bin/env bash
set -euo pipefail
# Idempotent scaffolding for Playwright project per step requirements
WORKSPACE="/home/kavia/workspace/code-generation/crossbrowser-test-automation-suite-296141-296150/playwright_native_test"
mkdir -p "$WORKSPACE" && cd "$WORKSPACE"
# Default Playwright Test version; allow override via PLAYWRIGHT_TEST_VER
PW_VERSION="^1.43.0"
[ -n "${PLAYWRIGHT_TEST_VER:-}" ] && PW_VERSION="$PLAYWRIGHT_TEST_VER"
export PW_VERSION
# Create package.json only if missing; otherwise merge scripts/devDependencies non-destructively
if [ ! -f package.json ]; then
  cat > package.json <<JSON
{
  "name": "playwright_native_test",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "test": "playwright test",
    "test:headless": "playwright test --reporter=list --workers=1"
  },
  "devDependencies": {
    "@playwright/test": "${PW_VERSION}"
  }
}
JSON
else
  # Merge in Node to keep JSON formatting and avoid destructive editing
  node - <<'NODE'
const fs=require('fs');const p='package.json';
const pkg=JSON.parse(fs.readFileSync(p));
pkg.scripts=pkg.scripts||{};
pkg.scripts['test']=pkg.scripts['test']||'playwright test';
pkg.scripts['test:headless']=pkg.scripts['test:headless']||'playwright test --reporter=list --workers=1';
pkg.devDependencies=pkg.devDependencies||{};
// Respect existing version, otherwise set from env PW_VERSION or fallback
pkg.devDependencies['@playwright/test']=pkg.devDependencies['@playwright/test']||process.env.PW_VERSION||'^1.43.0';
fs.writeFileSync(p,JSON.stringify(pkg,null,2));
NODE
fi
# Write playwright.config.js if missing (minimal CI-friendly settings)
if [ ! -f playwright.config.js ]; then
  cat > playwright.config.js <<'JS'
/** @type {import('@playwright/test').PlaywrightTestConfig} */
module.exports = {
  timeout: 15000,
  expect: { timeout: 5000 },
  use: { headless: true, launchOptions: { args: ["--no-sandbox","--disable-dev-shm-usage"] } },
  retries: 0
};
JS
fi
# Add deterministic sample test only if absent
mkdir -p tests
if [ ! -f tests/example.spec.js ]; then
  cat > tests/example.spec.js <<'TEST'
const { test, expect } = require('@playwright/test');

test('dom content stable check', async ({ page }) => {
  await page.setContent('<div id="ok">ok</div>');
  await expect(page.locator('#ok')).toHaveText('ok');
});
TEST
fi
# End of scaffold script
