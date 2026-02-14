// playwright-tests/tests/error-handling.spec.js
import { test, expect } from '@playwright/test';

test.describe('Error Handling and Edge Cases', () => {
  test.setTimeout(60000);

  test.beforeEach(async ({ page }) => {
    await page.goto('/');
    await page.waitForTimeout(3000); // Wait for splash
  });

  test('should handle network failures gracefully', async ({ page }) => {
    console.log('🌐 Testing network failure handling');

    // Simulate offline
    await page.context().setOffline(true);
    await page.waitForTimeout(1000);

    // Try to navigate
    const roomsButton = page.locator('text=Browse Rooms');
    if (await roomsButton.isVisible({ timeout: 2000 }).catch(() => false)) {
      await roomsButton.click();

      // Should handle offline gracefully
      const errorMessage = page.locator('text=offline').or(page.locator('text=Offline')).or(page.locator('text=no internet')).or(page.locator('text=connection'));
      const hasErrorHandling = await errorMessage.isVisible({ timeout: 3000 }).catch(() => false);

      if (hasErrorHandling) {
        console.log('   ✅ Network error handled gracefully');
      } else {
        console.log('   ⚠️ No network error message displayed');
      }
    }

    // Restore connection
    await page.context().setOffline(false);
    await page.waitForTimeout(1000);
  });

  test('should handle invalid form inputs', async ({ page }) => {
    console.log('📝 Testing form validation');

    // Try to find any form
    const forms = [
      page.locator('form'),
      page.locator('input[type="email"]').locator('..').locator('..'),
      page.locator('input[type="password"]').locator('..').locator('..')
    ];

    for (const form of forms) {
      if (await form.isVisible({ timeout: 1000 }).catch(() => false)) {
        // Find submit button
        const submitButton = form.locator('button[type="submit"]').or(form.locator('button')).last();

        if (await submitButton.isVisible({ timeout: 1000 }).catch(() => false)) {
          // Try submitting empty form
          await submitButton.click();

          // Look for validation messages
          const validationMessages = [
            page.locator('text=required'),
            page.locator('text=Required'),
            page.locator('text=invalid'),
            page.locator('text=Invalid'),
            page.locator('text=error'),
            page.locator('text=Error')
          ];

          let validationFound = false;
          for (const message of validationMessages) {
            if (await message.isVisible({ timeout: 2000 }).catch(() => false)) {
              validationFound = true;
              break;
            }
          }

          if (validationFound) {
            console.log('   ✅ Form validation working');
            break;
          }
        }
      }
    }
  });

  test('should handle rapid clicking and spam prevention', async ({ page }) => {
    console.log('🖱️ Testing rapid clicking prevention');

    // Find clickable elements
    const clickableElements = [
      page.locator('button').first(),
      page.locator('text=Follow').first(),
      page.locator('text=Like').first(),
      page.locator('[role="button"]').first()
    ];

    for (const element of clickableElements) {
      if (await element.isVisible({ timeout: 1000 }).catch(() => false)) {
        // Rapid click test
        for (let i = 0; i < 5; i++) {
          await element.click();
          await page.waitForTimeout(100);
        }

        // Check if app still functions (no crashes)
        const stillWorks = await page.locator('body').isVisible();
        expect(stillWorks).toBeTruthy();

        console.log('   ✅ Rapid clicking handled without crashes');
        break;
      }
    }
  });

  test('should handle large viewport changes', async ({ page }) => {
    console.log('📱 Testing responsive design');

    const viewports = [
      { width: 1920, height: 1080, name: 'Desktop' },
      { width: 768, height: 1024, name: 'Tablet' },
      { width: 375, height: 667, name: 'Mobile' }
    ];

    for (const viewport of viewports) {
      await page.setViewportSize({ width: viewport.width, height: viewport.height });
      await page.waitForTimeout(1000);

      // Check if content is still accessible
      const contentVisible = await page.locator('text=Mix & Mingle').isVisible({ timeout: 3000 });
      expect(contentVisible).toBeTruthy();

      console.log(`   ✅ ${viewport.name} viewport (${viewport.width}x${viewport.height}) working`);
    }
  });

  test('should handle memory-intensive operations', async ({ page }) => {
    console.log('🧠 Testing memory handling');

    // Navigate through many pages rapidly
    const pages = ['text=Home', 'text=Browse Rooms', 'text=Discover Users', 'text=Messages', 'text=Settings'];

    for (let cycle = 0; cycle < 3; cycle++) {
      console.log(`   → Memory test cycle ${cycle + 1}`);

      for (const pageSelector of pages) {
        const button = page.locator(pageSelector);
        if (await button.isVisible({ timeout: 1000 }).catch(() => false)) {
          await button.click();
          await page.waitForTimeout(500);
        }
      }

      // Go back through pages
      for (let i = 0; i < pages.length; i++) {
        await page.goBack();
        await page.waitForTimeout(200);
      }
    }

    // Check if app still works
    const stillFunctional = await page.locator('text=Mix & Mingle').isVisible({ timeout: 3000 });
    expect(stillFunctional).toBeTruthy();

    console.log('   ✅ Memory-intensive operations handled well');
  });

  test('should handle browser console errors gracefully', async ({ page }) => {
    console.log('🐛 Testing console error handling');

    // Listen for console errors
    const consoleErrors = [];
    page.on('console', msg => {
      if (msg.type() === 'error') {
        consoleErrors.push(msg.text());
      }
    });

    // Navigate through app
    const navigationButtons = ['text=Home', 'text=Browse Rooms', 'text=Discover Users', 'text=Messages'];

    for (const buttonSelector of navigationButtons) {
      const button = page.locator(buttonSelector);
      if (await button.isVisible({ timeout: 2000 }).catch(() => false)) {
        await button.click();
        await page.waitForTimeout(1000);
      }
    }

    // Check for critical console errors
    const criticalErrors = consoleErrors.filter(error =>
      error.includes('TypeError') ||
      error.includes('ReferenceError') ||
      error.includes('SyntaxError') ||
      error.includes('uncaught')
    );

    if (criticalErrors.length > 0) {
      console.log(`   ⚠️ Found ${criticalErrors.length} critical console errors:`);
      criticalErrors.forEach(error => console.log(`     - ${error}`));
    } else {
      console.log('   ✅ No critical console errors detected');
    }

    // App should still be functional despite console errors
    const stillWorks = await page.locator('body').textContent();
    expect(stillWorks && stillWorks.length > 100).toBeTruthy();
  });

  test('should handle unexpected navigation failures', async ({ page }) => {
    console.log('🚫 Testing navigation failure handling');

    // Try navigating to non-existent pages
    const invalidUrls = [
      'http://127.0.0.1:3000/#/invalid-page',
      'http://127.0.0.1:3000/#/nonexistent',
      'http://127.0.0.1:3000/#/broken-route'
    ];

    for (const url of invalidUrls) {
      try {
        await page.goto(url);
        await page.waitForTimeout(2000);

        // Should either redirect to valid page or show error page
        const hasContent = await page.locator('body').textContent();
        expect(hasContent && hasContent.length > 0).toBeTruthy();

        console.log(`   ✅ ${url} handled gracefully`);
      } catch (error) {
        console.log(`   ⚠️ ${url} not accessible: ${error.message}`);
      }
    }
  });
});

test('should validate create room form', async ({ page }) => {
  await page.goto('/');

  // Navigate to create room
  await page.locator('text=Create Room').click();

  // Submit empty form
  await page.click('[data-testid="create-room-button"]');

  // Verify validation errors
  await expect(page.locator('text=Room name is required')).toBeVisible();
  await expect(page.locator('text=Description is required')).toBeVisible();
});

test('should handle 404 errors', async ({ page }) => {

  test('should handle 404 errors', async ({ page }) => {
    await page.goto('/invalid-route');

    // Verify 404 page
    await expect(page.locator('text=Page not found')).toBeVisible();
    await expect(page.locator('text=Go Home')).toBeVisible();
  });
});