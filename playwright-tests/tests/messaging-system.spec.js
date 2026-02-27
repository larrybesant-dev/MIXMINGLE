// playwright-tests/tests/messaging-system.spec.js
import { test, expect } from "@playwright/test";

test.describe("Messaging System", () => {
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

  test("should send and receive messages", async ({ page }) => {
    await page.goto("/");

    // Navigate to messages
    await page.locator("text=Messages").click();

    // Check if conversations exist
    const conversationList = page.locator(".conversation-tile");
    if ((await conversationList.count()) > 0) {
      await conversationList.first().click();

      // Send message
      await page.fill('[data-testid="message-input"]', "Test message from Playwright");
      await page.click('[data-testid="send-button"]');

      // Verify message appears
      await expect(page.locator("text=Test message from Playwright")).toBeVisible();

      // Test message reactions
      await page.locator(".message-item").last().hover();
      await page.locator('[data-testid="react-button"]').click();
      await page.locator("text=👍").click();

      // Verify reaction appears
      await expect(page.locator(".reaction-emoji")).toBeVisible();
    } else {
      // No conversations - verify empty state
      await expect(page.locator("text=No messages yet")).toBeVisible();
    }
  });
});
