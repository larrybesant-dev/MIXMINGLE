import { test, expect } from "@playwright/test";

test.describe("Mix & Mingle - Happy Path E2E", () => {
  const timestamp = Date.now();
  const testEmail = `testuser+${timestamp}@example.com`;
  const testPassword = "Test123!!";

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

  test("Complete new user onboarding journey", async ({ page }) => {
    // Step 1: Load the app and verify splash page
    await page.goto("/");
    await expect(page).toHaveTitle(/Mix & Mingle/);

    // Wait for splash page to load
    await expect(page.locator("text=MIX & MINGLE")).toBeVisible();
    await expect(page.locator("text=Where Music Meets Connection")).toBeVisible();

    // Wait for navigation to login (should happen automatically after 2 seconds)
    await page.waitForURL("**/login", { timeout: 10000 });

    // Step 2: Sign up with test account
    await expect(page.locator("text=Create Account")).toBeVisible();

    // Click signup tab
    await page.locator("text=Sign Up").click();

    // Fill signup form
    await page.fill('input[placeholder*="email" i]', testEmail);
    await page.fill('input[placeholder*="password" i]', testPassword);
    await page.fill('input[placeholder*="confirm" i]', testPassword);

    // Submit signup
    await page.locator("text=Sign Up").click();

    // Wait for signup to complete and navigate to home
    await page.waitForURL("**/home", { timeout: 15000 });

    // Step 3: Verify home page loads correctly
    await expect(page.locator("text=MIX & MINGLE")).toBeVisible();

    // Check navigation buttons
    await expect(page.locator('button[aria-label*="Browse Rooms" i]')).toBeVisible();
    await expect(page.locator('button[aria-label*="Speed Dating" i]')).toBeVisible();
    await expect(page.locator('button[aria-label*="Search" i]')).toBeVisible();
    await expect(page.locator('button[aria-label*="Notifications" i]')).toBeVisible();
    await expect(page.locator('button[aria-label*="Profile" i]')).toBeVisible();

    // Check floating action button
    await expect(page.locator('button[aria-label*="Go Live" i]')).toBeVisible();

    // Step 4: Test browse rooms
    await page.locator('button[aria-label*="Browse Rooms" i]').click();
    await page.waitForURL("**/browse-rooms");

    await expect(page.locator("text=Browse Rooms")).toBeVisible();
    await expect(page.locator('button[aria-label*="search" i]')).toBeVisible();
    await expect(page.locator('button[aria-label*="filter" i]')).toBeVisible();

    // Go back to home
    await page.goBack();

    // Step 5: Test discover users
    await page.locator('button[aria-label*="Profile" i]').click();
    await page.waitForURL("**/profile");

    // Check profile tabs
    await expect(page.locator("text=Profile")).toBeVisible();
    await expect(page.locator("text=Rooms")).toBeVisible();
    await expect(page.locator("text=Timeline")).toBeVisible();

    // Test timeline "coming soon"
    await page.locator("text=Timeline").click();
    await expect(page.locator("text=Coming Soon")).toBeVisible();

    // Test rooms "coming soon"
    await page.locator("text=Rooms").click();
    await expect(page.locator("text=Coming Soon")).toBeVisible();

    // Go back to home
    await page.goBack();

    // Step 6: Test settings
    await page.locator('button[aria-label*="Profile" i]').click();
    await page.locator("text=Settings").click();
    await page.waitForURL("**/settings");

    await expect(page.locator("text=Settings")).toBeVisible();
    await expect(page.locator("text=Privacy Settings")).toBeVisible();
    await expect(page.locator("text=Agora Video Test")).toBeVisible();

    // Test privacy settings
    await page.locator("text=Privacy Settings").click();
    await page.waitForURL("**/privacy-settings");
    await expect(page.locator("text=Privacy Settings")).toBeVisible();

    // Go back
    await page.goBack();

    // Step 7: Test logout and login
    await page.locator("text=Logout").click();

    // Should navigate back to login
    await page.waitForURL("**/login");

    // Login with the test account
    await page.locator("text=Login").click();
    await page.fill('input[placeholder*="email" i]', testEmail);
    await page.fill('input[placeholder*="password" i]', testPassword);
    await page.locator("text=Login").click();

    // Should navigate to home
    await page.waitForURL("**/home");

    // Verify we're logged back in
    await expect(page.locator("text=MIX & MINGLE")).toBeVisible();
  });
});
