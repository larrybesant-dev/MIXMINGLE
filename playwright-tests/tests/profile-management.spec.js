// playwright-tests/tests/profile-management.spec.js
import { test, expect } from "@playwright/test";

test.describe("Profile Management", () => {
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

  test("should view and edit profile", async ({ page }) => {
    await page.goto("/");

    // Navigate to profile
    await page.locator("text=Profile").click();

    // Verify profile loads
    await expect(page.locator(".profile-header")).toBeVisible();

    // Edit profile
    await page.click('[data-testid="edit-profile-button"]');

    // Update profile information
    await page.fill('[data-testid="username"]', "testuser123");
    await page.fill('[data-testid="display-name"]', "Test User");
    await page.fill('[data-testid="bio"]', "This is a test bio");
    await page.selectOption('[data-testid="gender"]', "other");

    // Upload profile picture (if file input exists)
    const fileInput = page.locator('[data-testid="profile-picture-upload"]');
    if (await fileInput.isVisible()) {
      await fileInput.setInputFiles("./test-assets/test-image.jpg");
    }

    // Save changes
    await page.click('[data-testid="save-profile"]');

    // Verify changes saved
    await expect(page.locator("text=Profile updated successfully")).toBeVisible();
  });

  test("should manage profile interests and preferences", async ({ page }) => {
    await page.goto("/");

    // Navigate to profile
    await page.locator("text=Profile").click();

    // Edit interests
    await page.click('[data-testid="edit-interests"]');

    // Select interests
    await page.check('[data-testid="interest-music"]');
    await page.check('[data-testid="interest-gaming"]');
    await page.check('[data-testid="interest-chat"]');

    // Save interests
    await page.click('[data-testid="save-interests"]');

    // Verify interests saved
    await expect(page.locator("text=Interests updated")).toBeVisible();

    // Test preferences
    await page.click('[data-testid="edit-preferences"]');

    // Set preferences
    await page.selectOption('[data-testid="language"]', "en");
    await page.selectOption('[data-testid="theme"]', "dark");

    // Save preferences
    await page.click('[data-testid="save-preferences"]');

    // Verify preferences saved
    await expect(page.locator("text=Preferences updated")).toBeVisible();
  });
});
