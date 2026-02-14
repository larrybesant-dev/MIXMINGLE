// playwright-tests/tests/room-operations.spec.js
import { test, expect } from '@playwright/test';

test.describe('Room Operations', () => {
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

  test('should browse and join rooms', async ({ page }) => {
    await page.goto('/');

    // Navigate to home/browse rooms
    await page.locator('text=Browse Rooms').click();

    // Check if rooms are displayed
    const roomCards = page.locator('.room-card');
    if (await roomCards.count() > 0) {
      // Click on first room
      await roomCards.first().click();

      // Verify room details page loads
      await expect(page.locator('.room-details')).toBeVisible();

      // Test join room functionality
      await page.click('[data-testid="join-room-button"]');

      // Verify room interface loads
      await expect(page.locator('.room-interface')).toBeVisible();

      // Test room controls
      await page.click('[data-testid="mute-button"]');
      await page.click('[data-testid="video-toggle"]');

      // Test tipping system
      await page.click('[data-testid="tip-button"]');
      await page.fill('[data-testid="tip-amount"]', '10');
      await page.click('[data-testid="send-tip"]');

      // Verify tip sent
      await expect(page.locator('text=Tip sent!')).toBeVisible();
    } else {
      // No rooms - verify empty state
      await expect(page.locator('text=No rooms available')).toBeVisible();
    }
  });

  test('should create a new room', async ({ page }) => {
    await page.goto('/');

    // Navigate to create room
    await page.locator('text=Create Room').click();

    // Fill room creation form
    await page.fill('[data-testid="room-name"]', 'Test Room');
    await page.fill('[data-testid="room-description"]', 'Test room description');
    await page.selectOption('[data-testid="room-category"]', 'music');

    // Submit form
    await page.click('[data-testid="create-room-button"]');

    // Verify room created and redirected
    await expect(page.locator('.room-interface')).toBeVisible();
    await expect(page.locator('text=Test Room')).toBeVisible();
  });
});