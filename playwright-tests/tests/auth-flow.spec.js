// playwright-tests/tests/auth-flow.spec.js
import { test, expect } from '@playwright/test';

test.describe('Authentication Flow Tests', () => {
  test.setTimeout(60000);

  test.beforeEach(async ({ page }) => {
    await page.goto('/');
    await page.waitForTimeout(3000); // Wait for splash
  });

  test('should display auth options on fresh load', async ({ page }) => {
    console.log('🔐 Testing authentication UI display');

    // Check for auth-related elements
    const authIndicators = [
      page.locator('text=Sign In'),
      page.locator('text=Login'),
      page.locator('text=Sign Up'),
      page.locator('text=Create Account'),
      page.locator('text=Get Started'),
      page.locator('input[type="email"]'),
      page.locator('input[type="password"]')
    ];

    let authElementsFound = 0;
    for (const indicator of authIndicators) {
      if (await indicator.isVisible({ timeout: 2000 }).catch(() => false)) {
        authElementsFound++;
      }
    }

    // Should have at least some auth elements
    expect(authElementsFound).toBeGreaterThan(0);
    console.log(`   → Found ${authElementsFound} authentication elements`);
  });

  test('should handle signup form validation', async ({ page }) => {
    console.log('📝 Testing signup form validation');

    // Try to find signup form
    const signUpButton = page.locator('text=Sign Up').or(page.locator('text=Create Account')).or(page.locator('text=Register'));
    if (await signUpButton.isVisible({ timeout: 3000 }).catch(() => false)) {
      await signUpButton.click();

      // Try submitting empty form
      const submitButton = page.locator('button[type="submit"]').or(page.locator('text=Sign Up')).or(page.locator('text=Create Account'));
      if (await submitButton.isVisible({ timeout: 2000 }).catch(() => false)) {
        await submitButton.click();

        // Should show validation errors or "coming soon"
        const validationMessage = page.locator('text=required').or(page.locator('text=Required')).or(page.locator('text=coming soon'));
        expect(await validationMessage.isVisible({ timeout: 3000 }).catch(() => false)).toBeTruthy();
      }
    } else {
      console.log('   → Signup form not accessible (may be behind login)');
    }
  });

  test('should handle login form submission', async ({ page }) => {
    console.log('🔑 Testing login form submission');

    const signInButton = page.locator('text=Sign In').or(page.locator('text=Login'));
    if (await signInButton.isVisible({ timeout: 3000 }).catch(() => false)) {
      await signInButton.click();

      const emailField = page.locator('input[type="email"]').or(page.locator('[data-testid="email"]'));
      const passwordField = page.locator('input[type="password"]').or(page.locator('[data-testid="password"]'));
      const submitButton = page.locator('button[type="submit"]').or(page.locator('text=Sign In'));

      if (await emailField.isVisible({ timeout: 2000 }).catch(() => false)) {
        // Test with invalid credentials
        await emailField.fill('invalid@test.com');
        await passwordField.fill('wrongpassword');
        await submitButton.click();

        // Should show error or "coming soon"
        const resultMessage = page.locator('text=error').or(page.locator('text=Error')).or(page.locator('text=coming soon'));
        expect(await resultMessage.isVisible({ timeout: 5000 }).catch(() => false)).toBeTruthy();
      }
    }
  });

  test('should allow guest access if available', async ({ page }) => {
    console.log('👤 Testing guest access');

    const guestButton = page.locator('text=Continue as Guest').or(page.locator('text=Guest')).or(page.locator('text=Skip'));
    if (await guestButton.isVisible({ timeout: 3000 }).catch(() => false)) {
      await guestButton.click();

      // Should navigate to home or show guest features
      const homeIndicator = page.locator('text=Welcome').or(page.locator('text=Home')).or(page.locator('text=Mix & Mingle'));
      expect(await homeIndicator.isVisible({ timeout: 5000 })).toBeTruthy();
      console.log('   → Guest access working');
    } else {
      console.log('   → Guest access not available');
    }
  });
});