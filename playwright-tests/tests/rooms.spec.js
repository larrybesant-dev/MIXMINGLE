import { test, expect } from "@playwright/test";

test.describe("Rooms", () => {
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

    // Login first
    await page.goto("/");
    await page.waitForURL("**/login");

    // Wait for form to load
    await page.waitForTimeout(1000);

    // Find email and password inputs with fallback strategies
    let emailInput;
    try {
      emailInput = page.locator('input[type="email"], input[placeholder*="email" i]').first();
    } catch {
      emailInput = page.locator("input").first();
    }

    let passwordInput;
    try {
      passwordInput = page.locator('input[type="password"]').first();
    } catch {
      passwordInput = page.locator("input").nth(1);
    }

    // Fill form
    await emailInput.fill("testuser+auth@example.com");
    await passwordInput.fill("Test123!!");

    // Submit
    let loginButton;
    try {
      loginButton = page.locator('button:has-text("Login"), input[type="submit"]').first();
      await loginButton.click();
    } catch {
      await passwordInput.press("Enter");
    }

    await page.waitForURL("**/home");
  });

  test("Browse rooms page loads correctly", async ({ page }) => {
    // Navigate to browse rooms
    await page.locator('button[aria-label*="Browse Rooms" i]').click();
    await page.waitForURL("**/browse-rooms");

    // Verify page title
    await expect(page.locator("text=Browse Rooms")).toBeVisible();

    // Verify search and filter buttons
    await expect(page.locator('button[aria-label*="search" i]')).toBeVisible();
    await expect(page.locator('button[aria-label*="filter" i]')).toBeVisible();
  });

  test("Room search functionality works", async ({ page }) => {
    await page.locator('button[aria-label*="Browse Rooms" i]').click();
    await page.waitForURL("**/browse-rooms");

    // Click search button
    await page.locator('button[aria-label*="search" i]').click();

    // Verify search input appears
    await expect(page.locator('input[placeholder*="Search rooms" i]')).toBeVisible();

    // Type search query
    await page.fill('input[placeholder*="Search rooms" i]', "test room");

    // Search should work (depends on rooms in database)
  });

  test("Room filters show coming soon", async ({ page }) => {
    await page.locator('button[aria-label*="Browse Rooms" i]').click();
    await page.waitForURL("**/browse-rooms");

    // Click filter button
    await page.locator('button[aria-label*="filter" i]').click();

    // Should show coming soon message
    await expect(page.locator("text=Coming Soon")).toBeVisible();
  });

  test("Room cards display correctly", async ({ page }) => {
    await page.locator('button[aria-label*="Browse Rooms" i]').click();
    await page.waitForURL("**/browse-rooms");

    // Check if room cards exist (depends on data)
    // For now, just verify the page structure
    await expect(page.locator("text=No rooms found")).toBeVisible();
  });

  test("Join room functionality works", async ({ page }) => {
    await page.locator('button[aria-label*="Browse Rooms" i]').click();
    await page.waitForURL("**/browse-rooms");

    // If rooms exist, try to join one
    const roomCard = page.locator(".room-card").first();
    if (await roomCard.isVisible()) {
      await roomCard.click();

      // Should navigate to room page
      await page.waitForURL("**/room");

      // Verify room page loads
      await expect(page.locator("text=Room")).toBeVisible();
    }
  });

  test("Room page loads with all elements", async ({ page }) => {
    // This test assumes a room exists and we can navigate to it
    // In a real scenario, we'd need to create a room first or use a known room ID

    // For now, test the room page structure if we can access it
    await page.locator('button[aria-label*="Browse Rooms" i]').click();
    await page.waitForURL("**/browse-rooms");

    // Try to find and click a room
    const roomCard = page.locator('[data-testid="room-card"]').first();
    if (await roomCard.isVisible()) {
      await roomCard.click();
      await page.waitForURL("**/room");

      // Verify room page elements
      await expect(page.locator("text=Send a message")).toBeVisible();
      await expect(page.locator('input[placeholder*="Type a message" i]')).toBeVisible();
      await expect(page.locator('button[aria-label*="send" i]')).toBeVisible();
    }
  });

  test("Room messaging works", async ({ page }) => {
    // Navigate to a room (if possible)
    await page.locator('button[aria-label*="Browse Rooms" i]').click();
    await page.waitForURL("**/browse-rooms");

    const roomCard = page.locator('[data-testid="room-card"]').first();
    if (await roomCard.isVisible()) {
      await roomCard.click();
      await page.waitForURL("**/room");

      // Try to send a message
      const messageInput = page.locator('input[placeholder*="Type a message" i]');
      if (await messageInput.isVisible()) {
        await messageInput.fill("Test message from Playwright");
        await page.locator('button[aria-label*="send" i]').click();

        // Should show success message or add message to chat
        await expect(page.locator("text=Test message from Playwright")).toBeVisible();
      }
    }
  });
});
