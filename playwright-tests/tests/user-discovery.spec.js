// playwright-tests/tests/user-discovery.spec.js
import { test, expect } from '@playwright/test';

test.describe('User Discovery', () => {
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

  test('should discover and interact with users', async ({ page }) => {
    await page.goto('/');

    // Wait for page to load and take screenshot to see what's actually there
    await page.waitForTimeout(2000);
    await page.screenshot({ path: 'debug-home-page.png', fullPage: true });

    // Try to find any text containing "discover" (case insensitive)
    const discoverElements = await page.locator('text=/discover/i').all();
    console.log(`Found ${discoverElements.length} elements with 'discover' text`);

    if (discoverElements.length > 0) {
      // Click on the first discover element
      await discoverElements[0].click();
    } else {
      // Navigate to messages page first, as that's where "Discover Users" button is
      await page.goto('/messages');
      await page.waitForTimeout(1000);
      await page.screenshot({ path: 'debug-messages-page.png', fullPage: true });

      // Look for "Discover Users" button
      const discoverUsersButton = page.locator('text=Discover Users');
      if (await discoverUsersButton.isVisible()) {
        await discoverUsersButton.click();
      } else {
        throw new Error('Could not find Discover Users button on messages page');
      }
    }

    // Wait for discover users page to load
    await page.waitForTimeout(2000);
    await page.screenshot({ path: 'debug-discover-page.png', fullPage: true });

    // Check if users are displayed
    const userCards = page.locator('.user-card');
    if (await userCards.count() > 0) {
      // Click on first user
      await userCards.first().click();

      // Verify user profile loads
      await expect(page.locator('.user-profile')).toBeVisible();

      // Test follow/unfollow
      await page.click('[data-testid="follow-button"]');
      await expect(page.locator('text=Following')).toBeVisible();

      await page.click('[data-testid="follow-button"]');
      await expect(page.locator('text=Follow')).toBeVisible();

      // Test send message
      await page.click('[data-testid="send-message-button"]');

      // Verify redirected to messages
      await expect(page.locator('.message-interface')).toBeVisible();
    } else {
      // No users - verify empty state
      await expect(page.locator('text=No users found')).toBeVisible();
    }
  });

  test('should filter users by interests', async ({ page }) => {
    await page.goto('/');

    // Navigate to discover users
    await page.locator('text=Discover').click();

    // Apply filters
    await page.click('[data-testid="filter-button"]');
    await page.check('[data-testid="music-filter"]');
    await page.check('[data-testid="gaming-filter"]');
    await page.click('[data-testid="apply-filters"]');

    // Verify filtered results
    await expect(page.locator('.user-card')).toBeVisible();
  });
});