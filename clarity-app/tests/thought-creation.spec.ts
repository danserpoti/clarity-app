import { test, expect } from '@playwright/test';

test.describe('Thought Creation', () => {
  test('should allow a user to create and save a new thought', async ({ page }) => {
    // ブラウザのコンソールログを捕捉するリスナー
    page.on('console', async (msg) => {
      const msgType = msg.type();
      const msgText = msg.text();
      // 全ての種類のコンソールメッセージを出力
      console.log(`BROWSER CONSOLE [${msgType}]: ${msgText}`);
    });

    await page.goto('http://localhost:3000/');
    await expect(page.getByRole('heading', { name: 'Clarity' })).toBeVisible();

    console.log('Attempting to click "今すぐ記録を始める" link...');
    await page.getByRole('link', { name: '今すぐ記録を始める' }).click();
    console.log('Clicked link. URL immediately after click:', page.url());

    // 診断用のウェイトとログ
    console.log('Waiting for 1 second to see if URL changes without page.waitForURL...');
    await page.waitForTimeout(1000); // 1秒間の固定ウェイト
    console.log('URL after 1-second explicit wait:', page.url());

    try {
      console.log('Now, trying with page.waitForURL for /thoughts/new...');
      await page.waitForURL(/.*thoughts\/new/, { timeout: 10000 });
      console.log('Successfully navigated to:', page.url());
    } catch (e) {
      console.error('Failed to navigate. Current URL after timeout:', page.url());
      console.error('Consider checking the Playwright trace for more details (npx playwright show-report)');
      throw e;
    }

    await expect(page).toHaveURL(/.*thoughts\/new/);
    await expect(page.getByLabel('思考内容')).toBeVisible();
    const thoughtContent = '今日は新しいE2Eテストを書いた。';
    await page.getByLabel('思考内容').fill(thoughtContent);
    await page.getByLabel('カテゴリ').fill('テスト');
    await page.getByRole('button', { name: '保存' }).click();
    await expect(page.getByText(thoughtContent, { exact: false })).toBeVisible({ timeout: 10000 });
  });
});

