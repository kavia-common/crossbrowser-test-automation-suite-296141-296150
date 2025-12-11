import { test, expect } from '@playwright/test';

// PUBLIC_INTERFACE
test('homepage has title and links to intro page', async ({ page }) => {
  await page.goto('https://playwright.dev/');
  await expect(page).toHaveTitle(/Playwright/);
  const getStarted = page.getByRole('link', { name: 'Get started' });
  await expect(getStarted).toBeVisible();
});
