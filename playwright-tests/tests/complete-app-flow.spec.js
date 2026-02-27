// playwright-tests/tests/complete-app-flow.spec.js
import { test, expect } from "@playwright/test";

test.describe("Complete Mix & Mingle App Flow", () => {
  test.beforeEach(async ({ page }) => {
    // Health check - ensure app is accessible before running tests
    try {
      const response = await page.request.get("/");
      if (response.status() !== 200) {
        throw new Error(`App not accessible: ${response.status()}`);
      }
    } catch (error) {
      throw new Error(
        `Cannot connect to app server: ${error.message}. Make sure 'flutter run -d web-server --web-port=3000' is running.`,
      );
    }
  });

  test("should complete full user journey", async ({ page }) => {
    await page.goto("/");

    // 1. Splash Page
    await expect(page.locator("text=Mix & Mingle")).toBeVisible();
    await page.waitForTimeout(3000); // Splash timeout

    // 2. Authentication (if needed)
    const loginButton = page.locator("text=Sign In");
    if (await loginButton.isVisible()) {
      await loginButton.click();
      await page.fill('[data-testid="email"]', "test@example.com");
      await page.fill('[data-testid="password"]', "password123");
      await page.click('[data-testid="login-button"]');
    }

    // 3. Home Page Navigation
    await expect(page.locator("text=Welcome to Mix & Mingle")).toBeVisible();

    // Test all navigation buttons
    await page.locator('[data-testid="browse-rooms-btn"]').click();
    await expect(page.locator("text=Discover Live Rooms")).toBeVisible();
    await page.goBack();

    await page.locator('[data-testid="discover-users-btn"]').click();
    await expect(page.locator("text=Discover Users")).toBeVisible();
    await page.goBack();

    await page.locator('[data-testid="messages-btn"]').click();
    await expect(page.locator("text=Messages")).toBeVisible();
    await page.goBack();

    await page.locator('[data-testid="settings-btn"]').click();
    await expect(page.locator("text=Settings")).toBeVisible();
    await page.goBack();

    await page.locator('[data-testid="profile-btn"]').click();
    await expect(page.locator("text=Profile")).toBeVisible();
    await page.goBack();

    // 4. Test Coming Soon Features
    await page.locator('[data-testid="speed-dating-btn"]').click();
    await expect(page.locator("text=Coming Soon")).toBeVisible();
  });
});
