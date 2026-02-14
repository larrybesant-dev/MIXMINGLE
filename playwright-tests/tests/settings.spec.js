import { test, expect } from '@playwright/test';

test.describe('Settings', () => {
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

  test('Settings page loads correctly', async ({ page }) => {
    // Navigate to settings
    await page.locator('button[aria-label*="Profile" i]').click();
    await page.locator('text=Settings').click();
    await page.waitForURL('**/settings');

    // Verify page title
    await expect(page.locator('text=Settings')).toBeVisible();

    // Verify settings sections
    await expect(page.locator('text=Account')).toBeVisible();
    await expect(page.locator('text=Privacy')).toBeVisible();
    await expect(page.locator('text=Notifications')).toBeVisible();
  });

  test('Account settings display correctly', async ({ page }) => {
    await page.locator('button[aria-label*="Profile" i]').click();
    await page.locator('text=Settings').click();
    await page.waitForURL('**/settings');

    // Click Account section
    await page.locator('text=Account').click();

    // Verify account settings elements
    await expect(page.locator('text=Profile Picture')).toBeVisible();
    await expect(page.locator('text=Display Name')).toBeVisible();
    await expect(page.locator('text=Email')).toBeVisible();
    await expect(page.locator('text=Bio')).toBeVisible();
  });

  test('Profile picture upload works', async ({ page }) => {
    await page.locator('button[aria-label*="Profile" i]').click();
    await page.locator('text=Settings').click();
    await page.waitForURL('**/settings');

    await page.locator('text=Account').click();

    // Click change profile picture
    await page.locator('button[aria-label*="change profile picture" i]').click();

    // Should open file picker or camera
    // Note: File upload testing requires actual file handling
    await expect(page.locator('input[type="file"]')).toBeVisible();
  });

  test('Display name editing works', async ({ page }) => {
    await page.locator('button[aria-label*="Profile" i]').click();
    await page.locator('text=Settings').click();
    await page.waitForURL('**/settings');

    await page.locator('text=Account').click();

    // Click edit display name
    await page.locator('button[aria-label*="edit display name" i]').click();

    // Should show input field
    const nameInput = page.locator('input[placeholder*="Enter display name" i]');
    await expect(nameInput).toBeVisible();

    // Edit name
    await nameInput.fill('Test User Updated');

    // Save changes
    await page.locator('button[aria-label*="save" i]').click();

    // Should show success message
    await expect(page.locator('text=Display name updated')).toBeVisible();
  });

  test('Bio editing works', async ({ page }) => {
    await page.locator('button[aria-label*="Profile" i]').click();
    await page.locator('text=Settings').click();
    await page.waitForURL('**/settings');

    await page.locator('text=Account').click();

    // Click edit bio
    await page.locator('button[aria-label*="edit bio" i]').click();

    // Should show textarea
    const bioTextarea = page.locator('textarea[placeholder*="Tell us about yourself" i]');
    await expect(bioTextarea).toBeVisible();

    // Edit bio
    await bioTextarea.fill('This is a test bio from Playwright E2E testing.');

    // Save changes
    await page.locator('button[aria-label*="save" i]').click();

    // Should show success message
    await expect(page.locator('text=Bio updated')).toBeVisible();
  });

  test('Privacy settings work', async ({ page }) => {
    await page.locator('button[aria-label*="Profile" i]').click();
    await page.locator('text=Settings').click();
    await page.waitForURL('**/settings');

    // Click Privacy section
    await page.locator('text=Privacy').click();

    // Verify privacy toggles
    await expect(page.locator('text=Profile Visibility')).toBeVisible();
    await expect(page.locator('text=Show Online Status')).toBeVisible();
    await expect(page.locator('text=Allow Direct Messages')).toBeVisible();

    // Toggle profile visibility
    const visibilityToggle = page.locator('[data-testid="profile-visibility-toggle"]');
    await visibilityToggle.click();

    // Should show confirmation
    await expect(page.locator('text=Privacy settings updated')).toBeVisible();
  });

  test('Notification settings work', async ({ page }) => {
    await page.locator('button[aria-label*="Profile" i]').click();
    await page.locator('text=Settings').click();
    await page.waitForURL('**/settings');

    // Click Notifications section
    await page.locator('text=Notifications').click();

    // Verify notification toggles
    await expect(page.locator('text=Push Notifications')).toBeVisible();
    await expect(page.locator('text=Email Notifications')).toBeVisible();
    await expect(page.locator('text=Message Notifications')).toBeVisible();
    await expect(page.locator('text=Room Activity')).toBeVisible();

    // Toggle push notifications
    const pushToggle = page.locator('[data-testid="push-notifications-toggle"]');
    await pushToggle.click();

    // Should show confirmation
    await expect(page.locator('text=Notification settings updated')).toBeVisible();
  });

  test('Password change works', async ({ page }) => {
    await page.locator('button[aria-label*="Profile" i]').click();
    await page.locator('text=Settings').click();
    await page.waitForURL('**/settings');

    await page.locator('text=Account').click();

    // Click change password
    await page.locator('text=Change Password').click();

    // Should show password change form
    await expect(page.locator('input[placeholder*="Current password" i]')).toBeVisible();
    await expect(page.locator('input[placeholder*="New password" i]')).toBeVisible();
    await expect(page.locator('input[placeholder*="Confirm new password" i]')).toBeVisible();

    // Fill form
    await page.fill('input[placeholder*="Current password" i]', 'Test123!!');
    await page.fill('input[placeholder*="New password" i]', 'NewTest123!!');
    await page.fill('input[placeholder*="Confirm new password" i]', 'NewTest123!!');

    // Submit
    await page.locator('button[aria-label*="change password" i]').click();

    // Should show success message
    await expect(page.locator('text=Password changed successfully')).toBeVisible();
  });

  test('Account deletion warning appears', async ({ page }) => {
    await page.locator('button[aria-label*="Profile" i]').click();
    await page.locator('text=Settings').click();
    await page.waitForURL('**/settings');

    await page.locator('text=Account').click();

    // Click delete account
    await page.locator('text=Delete Account').click();

    // Should show confirmation dialog
    await expect(page.locator('text=Are you sure you want to delete your account?')).toBeVisible();
    await expect(page.locator('text=This action cannot be undone')).toBeVisible();

    // Cancel deletion
    await page.locator('button[aria-label*="cancel" i]').click();

    // Dialog should close
    await expect(page.locator('text=Are you sure you want to delete your account?')).not.toBeVisible();
  });

  test('Settings navigation works', async ({ page }) => {
    await page.locator('button[aria-label*="Profile" i]').click();
    await page.locator('text=Settings').click();
    await page.waitForURL('**/settings');

    // Test navigation between sections
    await page.locator('text=Privacy').click();
    await expect(page.locator('text=Profile Visibility')).toBeVisible();

    await page.locator('text=Notifications').click();
    await expect(page.locator('text=Push Notifications')).toBeVisible();

    await page.locator('text=Account').click();
    await expect(page.locator('text=Profile Picture')).toBeVisible();
  });

  test('Settings save confirmation works', async ({ page }) => {
    await page.locator('button[aria-label*="Profile" i]').click();
    await page.locator('text=Settings').click();
    await page.waitForURL('**/settings');

    await page.locator('text=Account').click();

    // Make a change
    await page.locator('button[aria-label*="edit display name" i]').click();
    await page.fill('input[placeholder*="Enter display name" i]', 'Test User Confirm');
    await page.locator('button[aria-label*="save" i]').click();

    // Should show loading state
    await expect(page.locator('text=Saving...')).toBeVisible();

    // Then success message
    await expect(page.locator('text=Display name updated')).toBeVisible();
  });
});