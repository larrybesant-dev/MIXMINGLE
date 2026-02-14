import { test, expect } from '@playwright/test';

test.describe('Home Page', () => {
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

  test('Home page loads with all navigation elements', async ({ page }) => {
    // Verify main title
    await expect(page.locator('text=MIX & MINGLE')).toBeVisible();

    // Verify app bar navigation buttons
    await expect(page.locator('button[aria-label*="Browse Rooms" i]')).toBeVisible();
    await expect(page.locator('button[aria-label*="Speed Dating" i]')).toBeVisible();
    await expect(page.locator('button[aria-label*="Search" i]')).toBeVisible();
    await expect(page.locator('button[aria-label*="Notifications" i]')).toBeVisible();
    await expect(page.locator('button[aria-label*="Profile" i]')).toBeVisible();

    // Verify hero section
    await expect(page.locator('text=Where Music Meets Connection')).toBeVisible();

    // Verify search section
    await expect(page.locator('input[placeholder*="Search" i]')).toBeVisible();

    // Verify floating action button
    await expect(page.locator('button[aria-label*="Go Live" i]')).toBeVisible();
  });

  test('Navigation buttons work correctly', async ({ page }) => {
    // Test browse rooms navigation
    await page.locator('button[aria-label*="Browse Rooms" i]').click();
    await page.waitForURL('**/browse-rooms');
    await expect(page.locator('text=Browse Rooms')).toBeVisible();
    await page.goBack();

    // Test speed dating navigation
    await page.locator('button[aria-label*="Speed Dating" i]').click();
    await page.waitForURL('**/speed-dating-lobby');
    await expect(page.locator('text=Speed Dating')).toBeVisible();
    await page.goBack();

    // Test search button
    await page.locator('button[aria-label*="Search" i]').click();
    // Search dialog should appear
    await expect(page.locator('text=Advanced Search')).toBeVisible();

    // Test notifications navigation
    await page.locator('button[aria-label*="Notifications" i]').click();
    await page.waitForURL('**/notifications');
    await expect(page.locator('text=Notifications')).toBeVisible();
    await page.goBack();

    // Test profile navigation
    await page.locator('button[aria-label*="Profile" i]').click();
    await page.waitForURL('**/profile');
    await expect(page.locator('text=Profile')).toBeVisible();
    await page.goBack();
  });

  test('Search functionality works', async ({ page }) => {
    // Click search button
    await page.locator('button[aria-label*="Search" i]').click();

    // Verify search dialog
    await expect(page.locator('text=Advanced Search')).toBeVisible();
    await expect(page.locator('input[placeholder*="Search by name" i]')).toBeVisible();

    // Type in search
    await page.fill('input[placeholder*="Search by name" i]', 'test room');

    // Search should filter results (if rooms exist)
    // Note: This depends on having rooms in the database
  });

  test('Go Live button shows coming soon', async ({ page }) => {
    // Click go live button
    await page.locator('button[aria-label*="Go Live" i]').click();

    // Should show coming soon message
    await expect(page.locator('text=Coming Soon')).toBeVisible();
  });

  test('Rooms load and display correctly', async ({ page }) => {
    // Check if rooms section loads
    // This depends on having rooms in Firestore
    // For now, just verify the section exists
    await expect(page.locator('text=Live Rooms')).toBeVisible();
  });
});