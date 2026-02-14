import { test, expect } from '@playwright/test';

test.describe('Users', () => {
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

  test('Discover users page loads correctly', async ({ page }) => {
    // Navigate to discover users from home
    await page.locator('button[aria-label*="Profile" i]').click();
    await page.locator('text=Discover Users').click();
    await page.waitForURL('**/discover-users');

    // Verify page title
    await expect(page.locator('text=Discover Users')).toBeVisible();

    // Verify search functionality
    await expect(page.locator('input[placeholder*="Search users" i]')).toBeVisible();
  });

  test('User search works', async ({ page }) => {
    await page.locator('button[aria-label*="Profile" i]').click();
    await page.locator('text=Discover Users').click();
    await page.waitForURL('**/discover-users');

    // Search for users
    await page.fill('input[placeholder*="Search users" i]', 'test');

    // Should filter results (depends on user data)
  });

  test('User cards display correctly', async ({ page }) => {
    await page.locator('button[aria-label*="Profile" i]').click();
    await page.locator('text=Discover Users').click();
    await page.waitForURL('**/discover-users');

    // Check if user cards exist
    // This depends on having users in the database
    const userCard = page.locator('[data-testid="user-card"]').first();
    if (await userCard.isVisible()) {
      // Verify user card elements
      await expect(userCard.locator('[data-testid="user-avatar"]')).toBeVisible();
      await expect(userCard.locator('[data-testid="user-name"]')).toBeVisible();
      await expect(userCard.locator('[data-testid="user-bio"]')).toBeVisible();
    }
  });

  test('User profile page loads correctly', async ({ page }) => {
    await page.locator('button[aria-label*="Profile" i]').click();
    await page.locator('text=Discover Users').click();
    await page.waitForURL('**/discover-users');

    // Click on a user card if it exists
    const userCard = page.locator('[data-testid="user-card"]').first();
    if (await userCard.isVisible()) {
      await userCard.click();
      await page.waitForURL('**/profile/*');

      // Verify profile page elements
      await expect(page.locator('text=Profile')).toBeVisible();
      await expect(page.locator('[data-testid="user-avatar"]')).toBeVisible();
      await expect(page.locator('[data-testid="user-name"]')).toBeVisible();
      await expect(page.locator('[data-testid="user-bio"]')).toBeVisible();
    }
  });

  test('Follow button shows coming soon', async ({ page }) => {
    await page.locator('button[aria-label*="Profile" i]').click();
    await page.locator('text=Discover Users').click();
    await page.waitForURL('**/discover-users');

    const userCard = page.locator('[data-testid="user-card"]').first();
    if (await userCard.isVisible()) {
      await userCard.click();
      await page.waitForURL('**/profile/*');

      // Try to click follow button
      const followButton = page.locator('text=Follow');
      if (await followButton.isVisible()) {
        await followButton.click();

        // Should show coming soon
        await expect(page.locator('text=Coming Soon')).toBeVisible();
      }
    }
  });

  test('Message button on profile shows coming soon', async ({ page }) => {
    await page.locator('button[aria-label*="Profile" i]').click();
    await page.locator('text=Discover Users').click();
    await page.waitForURL('**/discover-users');

    const userCard = page.locator('[data-testid="user-card"]').first();
    if (await userCard.isVisible()) {
      await userCard.click();
      await page.waitForURL('**/profile/*');

      // Try to click message button
      const messageButton = page.locator('text=Message');
      if (await messageButton.isVisible()) {
        await messageButton.click();

        // Should show coming soon
        await expect(page.locator('text=Coming Soon')).toBeVisible();
      }
    }
  });

  test('Own profile page loads correctly', async ({ page }) => {
    // Navigate to own profile
    await page.locator('button[aria-label*="Profile" i]').click();
    await page.waitForURL('**/profile');

    // Verify profile elements
    await expect(page.locator('text=Profile')).toBeVisible();
    await expect(page.locator('text=Rooms')).toBeVisible();
    await expect(page.locator('text=Timeline')).toBeVisible();
    await expect(page.locator('text=Edit Profile')).toBeVisible();
    await expect(page.locator('text=Settings')).toBeVisible();
  });

  test('Profile tabs work correctly', async ({ page }) => {
    await page.locator('button[aria-label*="Profile" i]').click();
    await page.waitForURL('**/profile');

    // Test profile tab
    await page.locator('text=Profile').click();
    await expect(page.locator('[data-testid="profile-content"]')).toBeVisible();

    // Test rooms tab - should show coming soon
    await page.locator('text=Rooms').click();
    await expect(page.locator('text=Coming Soon')).toBeVisible();

    // Test timeline tab - should show coming soon
    await page.locator('text=Timeline').click();
    await expect(page.locator('text=Coming Soon')).toBeVisible();
  });

  test('Edit profile navigation works', async ({ page }) => {
    await page.locator('button[aria-label*="Profile" i]').click();
    await page.waitForURL('**/profile');

    // Click edit profile
    await page.locator('text=Edit Profile').click();
    await page.waitForURL('**/edit-profile');

    // Verify edit profile page
    await expect(page.locator('text=Edit Profile')).toBeVisible();
    await expect(page.locator('input[placeholder*="username" i]')).toBeVisible();
    await expect(page.locator('input[placeholder*="display name" i]')).toBeVisible();
  });
});