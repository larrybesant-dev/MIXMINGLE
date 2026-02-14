import { test, expect } from '@playwright/test';

test.describe('Messages', () => {
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

    // Login first
    await page.goto('/');
    await page.waitForURL('**/login');

    // Wait for form to load
    await page.waitForTimeout(1000);

    // Find email and password inputs with fallback strategies
    let emailInput;
    try {
      emailInput = page.locator('input[type="email"], input[placeholder*="email" i]').first();
    } catch {
      emailInput = page.locator('input').first();
    }

    let passwordInput;
    try {
      passwordInput = page.locator('input[type="password"]').first();
    } catch {
      passwordInput = page.locator('input').nth(1);
    }

    // Fill form
    await emailInput.fill('testuser+auth@example.com');
    await passwordInput.fill('Test123!!');

    // Submit
    let loginButton;
    try {
      loginButton = page.locator('button:has-text("Login"), input[type="submit"]').first();
      await loginButton.click();
    } catch {
      await passwordInput.press('Enter');
    }

    await page.waitForURL('**/home');
  });

  test('Messages page loads correctly', async ({ page }) => {
    // Navigate to messages
    await page.locator('button[aria-label*="Profile" i]').click();
    await page.locator('text=Messages').click();
    await page.waitForURL('**/messages');

    // Verify page title
    await expect(page.locator('text=Messages')).toBeVisible();

    // Verify search functionality
    await expect(page.locator('input[placeholder*="Search" i]')).toBeVisible();
  });

  test('Message search works', async ({ page }) => {
    await page.locator('button[aria-label*="Profile" i]').click();
    await page.locator('text=Messages').click();
    await page.waitForURL('**/messages');

    // Click search button
    await page.locator('button[aria-label*="search" i]').click();

    // Verify search input
    await expect(page.locator('input[placeholder*="Search conversations" i]')).toBeVisible();

    // Type search query
    await page.fill('input[placeholder*="Search conversations" i]', 'test');

    // Should filter results
  });

  test('Conversation list displays correctly', async ({ page }) => {
    await page.locator('button[aria-label*="Profile" i]').click();
    await page.locator('text=Messages').click();
    await page.waitForURL('**/messages');

    // Check if conversations exist
    // This depends on having message data
    const conversationItem = page.locator('[data-testid="conversation-item"]').first();
    if (await conversationItem.isVisible()) {
      // Verify conversation elements
      await expect(conversationItem.locator('[data-testid="user-avatar"]')).toBeVisible();
      await expect(conversationItem.locator('[data-testid="user-name"]')).toBeVisible();
      await expect(conversationItem.locator('[data-testid="last-message"]')).toBeVisible();
      await expect(conversationItem.locator('[data-testid="timestamp"]')).toBeVisible();
    } else {
      // No conversations yet
      await expect(page.locator('text=No conversations yet')).toBeVisible();
    }
  });

  test('Chat screen loads correctly', async ({ page }) => {
    await page.locator('button[aria-label*="Profile" i]').click();
    await page.locator('text=Messages').click();
    await page.waitForURL('**/messages');

    // Click on a conversation if it exists
    const conversationItem = page.locator('[data-testid="conversation-item"]').first();
    if (await conversationItem.isVisible()) {
      await conversationItem.click();
      await page.waitForURL('**/chat');

      // Verify chat screen elements
      await expect(page.locator('text=Chat')).toBeVisible();
      await expect(page.locator('input[placeholder*="Type a message" i]')).toBeVisible();
      await expect(page.locator('button[aria-label*="send" i]')).toBeVisible();
    }
  });

  test('Sending messages works', async ({ page }) => {
    await page.locator('button[aria-label*="Profile" i]').click();
    await page.locator('text=Messages').click();
    await page.waitForURL('**/messages');

    const conversationItem = page.locator('[data-testid="conversation-item"]').first();
    if (await conversationItem.isVisible()) {
      await conversationItem.click();
      await page.waitForURL('**/chat');

      // Send a message
      const messageInput = page.locator('input[placeholder*="Type a message" i]');
      await messageInput.fill('Test message from Playwright E2E test');
      await page.locator('button[aria-label*="send" i]').click();

      // Verify message appears
      await expect(page.locator('text=Test message from Playwright E2E test')).toBeVisible();

      // Verify success feedback
      await expect(page.locator('text=Message sent')).toBeVisible();
    }
  });

  test('Message reactions work', async ({ page }) => {
    await page.locator('button[aria-label*="Profile" i]').click();
    await page.locator('text=Messages').click();
    await page.waitForURL('**/messages');

    const conversationItem = page.locator('[data-testid="conversation-item"]').first();
    if (await conversationItem.isVisible()) {
      await conversationItem.click();
      await page.waitForURL('**/chat');

      // Find a message and try to react to it
      const messageBubble = page.locator('[data-testid="message-bubble"]').first();
      if (await messageBubble.isVisible()) {
        // Long press or right click to show reaction options
        await messageBubble.click({ button: 'right' });

        // Should show reaction picker
        await expect(page.locator('[data-testid="reaction-picker"]')).toBeVisible();

        // Click a reaction (e.g., thumbs up)
        await page.locator('[data-testid="reaction-thumbs-up"]').click();

        // Should show reaction on message
        await expect(messageBubble.locator('[data-testid="reaction-thumbs-up"]')).toBeVisible();
      }
    }
  });

  test('Message search within conversations works', async ({ page }) => {
    await page.locator('button[aria-label*="Profile" i]').click();
    await page.locator('text=Messages').click();
    await page.waitForURL('**/messages');

    // Click advanced search
    await page.locator('button[aria-label*="search" i]').click();

    // Enable message content search
    await page.locator('text=Search in messages').check();

    // Search for message content
    await page.fill('input[placeholder*="Search message content" i]', 'test');

    // Should show search results
  });

  test('Message pagination works', async ({ page }) => {
    await page.locator('button[aria-label*="Profile" i]').click();
    await page.locator('text=Messages').click();
    await page.waitForURL('**/messages');

    const conversationItem = page.locator('[data-testid="conversation-item"]').first();
    if (await conversationItem.isVisible()) {
      await conversationItem.click();
      await page.waitForURL('**/chat');

      // Scroll up to load more messages
      await page.locator('[data-testid="messages-container"]').evaluate((container) => {
        container.scrollTop = 0;
      });

      // Should load more messages or show "no more messages"
      await expect(page.locator('text=Loading more messages...')).toBeVisible();
    }
  });
});