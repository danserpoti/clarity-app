import { test, expect } from '@playwright/test';

test('has title', async ({ page }) => {
  await page.goto('http://localhost:3000/');

  // Expect a title "to contain" a substring.
  await expect(page).toHaveTitle(/Clarity/);
});

test('get started link', async ({ page }) => {
  await page.goto('http://localhost:3000/');

  // Click the get started link.
  // Replace 'text=Get Started' with a locator that accurately targets an element on your page.
  // For example, if you have a button with the text "新規記録", you can use:
  // await page.getByRole('button', { name: '新規記録' }).click();

  // For now, we'll just check if the main page has a heading.
  // Please update this selector to match your application's structure.
  const heading = page.getByRole('heading', { name: 'Clarity' });
  await expect(heading).toBeVisible();
});

//
