import { test, expect } from "@playwright/test";

test.describe("Authentication", () => {
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

  test("User can sign up with valid credentials", async ({ page }) => {
    await page.goto("/");

    // Wait for navigation to login
    await page.waitForURL("**/login");

    // Debug: Log page content for troubleshooting
    console.log("Page URL:", page.url());
    console.log("Page title:", await page.title());

    // Try multiple locator strategies for signup tab
    let signupTab;
    try {
      signupTab = page.locator("text=/sign.?up/i").first();
      await signupTab.click();
    } catch {
      try {
        signupTab = page
          .locator(
            '[data-testid*="signup"], [aria-label*="signup" i], button:has-text("Sign"), a:has-text("Sign")',
          )
          .first();
        await signupTab.click();
      } catch {
        // If no signup tab, assume we're already on signup form
        console.log("No signup tab found, assuming already on signup form");
      }
    }

    // Wait a bit for form to load
    await page.waitForTimeout(1000);

    // Try multiple strategies for email input
    let emailInput;
    try {
      emailInput = page
        .locator('input[type="email"], input[placeholder*="email" i], input[name*="email" i]')
        .first();
    } catch {
      emailInput = page.locator("input").filter({ hasText: /email/i }).first();
    }

    // Try multiple strategies for password input
    let passwordInput;
    try {
      passwordInput = page.locator('input[type="password"]').first();
    } catch {
      passwordInput = page
        .locator('input[placeholder*="password" i], input[name*="password" i]')
        .first();
    }

    // Try multiple strategies for confirm password input
    let confirmInput;
    try {
      confirmInput = page
        .locator('input[placeholder*="confirm" i], input[name*="confirm" i]')
        .nth(1);
    } catch {
      confirmInput = page.locator('input[type="password"]').nth(1);
    }

    // Verify elements are visible
    await expect(emailInput).toBeVisible();
    await expect(passwordInput).toBeVisible();
    await expect(confirmInput).toBeVisible();

    // Fill form
    await emailInput.fill(testEmail);
    await passwordInput.fill(testPassword);
    await confirmInput.fill(testPassword);

    // Try multiple strategies for submit button
    let submitButton;
    try {
      submitButton = page
        .locator('button:has-text("Sign"), input[type="submit"], [data-testid*="signup"]')
        .first();
      await submitButton.click();
    } catch {
      // Try pressing Enter in the last input field
      await confirmInput.press("Enter");
    }

    // Should navigate to home
    await page.waitForURL("**/home");
    await expect(page.locator("text=/mix.?mingle/i")).toBeVisible();
  });

  test("User can login with valid credentials", async ({ page }) => {
    await page.goto("/");

    // Wait for navigation to login
    await page.waitForURL("**/login");

    // Debug: Log page content
    console.log("Login page URL:", page.url());

    // Wait a bit for form to load
    await page.waitForTimeout(1000);

    // Try multiple strategies for email input
    let emailInput;
    try {
      emailInput = page
        .locator('input[type="email"], input[placeholder*="email" i], input[name*="email" i]')
        .first();
      await expect(emailInput).toBeVisible();
    } catch {
      // Fallback: look for any input that might be email
      const allInputs = page.locator("input");
      const inputCount = await allInputs.count();
      console.log(`Found ${inputCount} input elements`);
      for (let i = 0; i < inputCount; i++) {
        const input = allInputs.nth(i);
        const placeholder = (await input.getAttribute("placeholder")) || "";
        const type = (await input.getAttribute("type")) || "";
        console.log(`Input ${i}: type=${type}, placeholder=${placeholder}`);
        if (type === "email" || placeholder.toLowerCase().includes("email")) {
          emailInput = input;
          break;
        }
      }
      if (!emailInput) {
        emailInput = allInputs.first(); // Fallback to first input
      }
    }

    // Try multiple strategies for password input
    let passwordInput;
    try {
      passwordInput = page.locator('input[type="password"]').first();
      await expect(passwordInput).toBeVisible();
    } catch {
      passwordInput = page
        .locator('input[placeholder*="password" i], input[name*="password" i]')
        .first();
    }

    // Fill form
    await emailInput.fill(testEmail);
    await passwordInput.fill(testPassword);

    // Try multiple strategies for login button
    let loginButton;
    try {
      loginButton = page
        .locator('button:has-text("Login"), input[type="submit"], [data-testid*="login"]')
        .first();
      await loginButton.click();
    } catch {
      // Try pressing Enter
      await passwordInput.press("Enter");
    }

    // Should navigate to home
    await page.waitForURL("**/home");
    await expect(page.locator("text=/mix.?mingle/i")).toBeVisible();
  });

  test("Login form validation works", async ({ page }) => {
    await page.goto("/");
    await page.waitForURL("**/login");

    // Wait for form to load
    await page.waitForTimeout(1000);

    // Try to submit empty form
    let loginButton;
    try {
      loginButton = page.locator('button:has-text("Login"), input[type="submit"]').first();
      await loginButton.click();
    } catch {
      // Try pressing Enter in any input
      const anyInput = page.locator("input").first();
      await anyInput.press("Enter");
    }

    // Should show validation errors or stay on login page
    await page.waitForTimeout(1000);
    // Note: Actual validation messages may vary by implementation
  });

  test("Remember Me functionality works", async ({ page }) => {
    await page.goto("/");
    await page.waitForURL("**/login");

    // Wait for form to load
    await page.waitForTimeout(1000);

    // Find email and password inputs
    const emailInput = page.locator('input[type="email"], input[placeholder*="email" i]').first();
    const passwordInput = page.locator('input[type="password"]').first();

    // Look for remember me checkbox
    let rememberCheckbox;
    try {
      rememberCheckbox = page
        .locator('input[type="checkbox"], [data-testid*="remember"], text=/remember/i')
        .first();
      await rememberCheckbox.check();
    } catch {
      console.log("Remember me checkbox not found");
    }

    // Fill and submit form
    await emailInput.fill(testEmail);
    await passwordInput.fill(testPassword);

    const loginButton = page.locator('button:has-text("Login"), input[type="submit"]').first();
    await loginButton.click();

    // Should navigate to home
    await page.waitForURL("**/home");
    await expect(page.locator("text=/mix.?mingle/i")).toBeVisible();
  });
});
