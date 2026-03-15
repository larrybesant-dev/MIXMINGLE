// playwright-tests/tests/debug-live-app.spec.js
import { test, expect } from "@playwright/test";

test.describe("Debug Live App", () => {
  test("should inspect the live app structure", async ({ page }) => {
    // Listen for all console messages
    const consoleMessages = [];
    const errors = [];
    page.on("console", (msg) => {
      consoleMessages.push(`${msg.type()}: ${msg.text()}`);
      console.log(`Console ${msg.type()}:`, msg.text());
    });

    // Listen for page errors
    page.on("pageerror", (error) => {
      console.log("Page error:", error.message);
      errors.push(error.message);
    });

    await page.goto("/");

    // Wait for page to load
    await page.waitForTimeout(10000);

    // Take screenshot
    await page.screenshot({ path: "live-app-home.png", fullPage: true });

    // Get page title
    const title = await page.title();
    console.log("Page title:", title);

    // Check if Flutter canvas is present
    const flutterCanvas = await page.locator("canvas").count();
    console.log("Flutter canvas elements:", flutterCanvas);

    // Check for Flutter view
    const flutterView = await page.locator(".flutter-view").count();
    console.log("Flutter view elements:", flutterView);

    // Get all text content
    const allText = await page.locator("body").textContent();
    console.log("Page text content length:", allText.length);
    console.log("First 500 characters:", allText.substring(0, 500));

    // Look for common elements
    const buttons = await page.locator("button").all();
    console.log("Number of buttons found:", buttons.length);

    // Look for any visible text
    const visibleText = await page.locator("body").innerText();
    console.log("Visible text length:", visibleText.length);
    console.log("Visible text:", visibleText.substring(0, 200));

    // Check network requests for failures
    const failedRequests = [];
    page.on("requestfailed", (request) => {
      failedRequests.push({
        url: request.url(),
        failure: request.failure(),
      });
      console.log("Failed request:", request.url(), request.failure());
    });

    // Wait a bit more
    await page.waitForTimeout(5000);

    console.log("Total console/page errors:", errors.length);
    console.log("Total console messages:", consoleMessages.length);
    console.log("All console messages:", consoleMessages);
    console.log("Total failed requests:", failedRequests.length);

    // Always pass this test
    expect(true).toBe(true);
  });
});
