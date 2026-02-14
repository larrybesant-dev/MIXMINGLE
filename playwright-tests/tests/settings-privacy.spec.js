// playwright-tests/tests/settings-privacy.spec.js
import { test, expect } from '@playwright/test';

test.describe('Settings and Privacy', () => {
  test.beforeEach(async ({ page }) => {
    // Health check - ensure app is accessible before running tests
    try {
      const response = await page.request.get('/');
      if (response.status() !== 200) {
        throw new Error(`App not accessible: ${response.status()}`);
      }
    } catch (error) {
      throw new Error(`Cannot connect to app server: ${error.message}. Make sure 'flutter run -d web-server --web-port=3000' is running.`);
    }
  });

  test('should manage account settings', async ({ page }) => {
    await page.goto('/');

    // Navigate to settings
    await page.locator('text=Settings').click();

    // Test profile settings
    await page.click('text=Profile');
    await page.fill('[data-testid="display-name"]', 'Test User');
    await page.fill('[data-testid="bio"]', 'Test bio');
    await page.click('[data-testid="save-profile"]');

    // Verify changes saved
    await expect(page.locator('text=Profile updated')).toBeVisible();

    // Test privacy settings
    await page.click('text=Privacy');
    await page.check('[data-testid="profile-visibility"]');
    await page.uncheck('[data-testid="show-online-status"]');
    await page.click('[data-testid="save-privacy"]');

    // Verify privacy settings saved
    await expect(page.locator('text=Privacy settings updated')).toBeVisible();

    // Test notification settings
    await page.click('text=Notifications');
    await page.check('[data-testid="message-notifications"]');
    await page.uncheck('[data-testid="room-notifications"]');
    await page.click('[data-testid="save-notifications"]');

    // Verify notification settings saved
    await expect(page.locator('text=Notification settings updated')).toBeVisible();
  });

  test('should manage blocked users', async ({ page }) => {
    await page.goto('/');

    // Navigate to settings
    await page.locator('text=Settings').click();

    // Go to blocked users
    await page.click('text=Blocked Users');

    // Check if blocked users list exists
    const blockedUsers = page.locator('.blocked-user-item');
    if (await blockedUsers.count() > 0) {
      // Unblock first user
      await blockedUsers.first().locator('[data-testid="unblock-button"]').click();
      await expect(page.locator('text=User unblocked')).toBeVisible();
    } else {
      // No blocked users - verify empty state
      await expect(page.locator('text=No blocked users')).toBeVisible();
    }
  });
});