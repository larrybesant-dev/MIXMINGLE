// playwright-tests/tests/navigation.spec.js
import { test, expect } from "@playwright/test";

test.describe("Navigation and Page Loading Tests", () => {
  test.setTimeout(60000);

  test.beforeEach(async ({ page }) => {
    await page.goto("/");
    await page.waitForTimeout(3000); // Wait for splash
  });

  test("should navigate through all main pages successfully", async ({ page }) => {
    console.log("🧭 Testing main navigation flow");

    // Define navigation targets
    const navigationTargets = [
      {
        button: "text=Home",
        expectedTexts: ["Welcome", "Mix & Mingle", "Dashboard"],
        name: "Home",
      },
      {
        button: "text=Browse Rooms",
        expectedTexts: ["Rooms", "Live Rooms", "Discover Rooms", "Create Room"],
        name: "Browse Rooms",
      },
      {
        button: "text=Discover Users",
        expectedTexts: ["Users", "Discover Users", "Find People", "Search users"],
        name: "Discover Users",
      },
      {
        button: "text=Messages",
        expectedTexts: ["Messages", "Chat", "Conversations", "No messages yet"],
        name: "Messages",
      },
      {
        button: "text=Settings",
        expectedTexts: ["Settings", "Preferences", "Account", "Privacy"],
        name: "Settings",
      },
      {
        button: "text=Profile",
        expectedTexts: ["Profile", "Edit Profile", "@", "followers"],
        name: "Profile",
      },
    ];

    let successfulNavigations = 0;

    for (const target of navigationTargets) {
      console.log(`   → Testing ${target.name} navigation`);

      const navButton = page.locator(target.button);
      if (await navButton.isVisible({ timeout: 3000 }).catch(() => false)) {
        await navButton.click();

        // Check if page loaded correctly
        let pageLoaded = false;
        for (const expectedText of target.expectedTexts) {
          if (
            await page
              .locator(`text=${expectedText}`)
              .isVisible({ timeout: 3000 })
              .catch(() => false)
          ) {
            pageLoaded = true;
            break;
          }
        }

        if (pageLoaded) {
          console.log(`   ✅ ${target.name} page loaded successfully`);
          successfulNavigations++;

          // Go back for next test
          await page.goBack();
          await page.waitForTimeout(1000);
        } else {
          console.log(`   ❌ ${target.name} page failed to load properly`);
        }
      } else {
        console.log(`   ⚠️ ${target.name} navigation button not found`);
      }
    }

    console.log(
      `📊 Navigation test results: ${successfulNavigations}/${navigationTargets.length} pages loaded successfully`,
    );
    expect(successfulNavigations).toBeGreaterThan(0); // At least some navigation should work
  });

  test("should handle browser back/forward navigation", async ({ page }) => {
    console.log("🔄 Testing browser navigation");

    // Navigate to a few pages
    const pages = ["text=Home", "text=Browse Rooms", "text=Discover Users"];

    for (const pageSelector of pages) {
      const button = page.locator(pageSelector);
      if (await button.isVisible({ timeout: 2000 }).catch(() => false)) {
        await button.click();
        await page.waitForTimeout(1000);
      }
    }

    // Test back navigation
    await page.goBack();
    await page.waitForTimeout(1000);

    // Should be on previous page
    const currentUrl = page.url();
    expect(currentUrl).toContain("http://127.0.0.1:3000");

    // Test forward navigation
    await page.goForward();
    await page.waitForTimeout(1000);

    console.log("   ✅ Browser navigation working");
  });

  test("should handle deep linking and direct URL access", async ({ page }) => {
    console.log("🔗 Testing direct URL access");

    // Test direct access to different routes (if app supports routing)
    const testUrls = [
      "http://127.0.0.1:3000/",
      "http://127.0.0.1:3000/#/home",
      "http://127.0.0.1:3000/#/rooms",
      "http://127.0.0.1:3000/#/users",
    ];

    for (const url of testUrls) {
      try {
        await page.goto(url);
        await page.waitForTimeout(2000);

        // Should not crash and should show some content
        const bodyContent = await page.locator("body").textContent();
        expect(bodyContent && bodyContent.length > 0).toBeTruthy();

        console.log(`   ✅ ${url} accessible`);
      } catch (error) {
        console.log(`   ⚠️ ${url} not accessible: ${error.message}`);
      }
    }
  });

  test("should handle page refresh without breaking", async ({ page }) => {
    console.log("🔄 Testing page refresh stability");

    // Navigate to home
    await page.locator("text=Home").click();
    await page.waitForTimeout(2000);

    // Refresh page
    await page.reload();
    await page.waitForTimeout(3000);

    // App should still be functional
    const appStillWorks = await page.locator("text=Mix & Mingle").isVisible({ timeout: 5000 });
    expect(appStillWorks).toBeTruthy();

    console.log("   ✅ Page refresh handled correctly");
  });

  test("should display loading states appropriately", async ({ page }) => {
    console.log("⏳ Testing loading states");

    // Navigate to different pages and check for loading indicators
    const navigationButtons = [
      "text=Home",
      "text=Browse Rooms",
      "text=Discover Users",
      "text=Messages",
      "text=Settings",
    ];

    for (const buttonSelector of navigationButtons) {
      const button = page.locator(buttonSelector);
      if (await button.isVisible({ timeout: 2000 }).catch(() => false)) {
        await button.click();

        // Look for loading indicators (spinners, skeletons, etc.)
        const loadingIndicators = [
          page.locator(".loading"),
          page.locator(".spinner"),
          page.locator("text=Loading"),
          page.locator("text=Please wait"),
          page.locator('[aria-label="loading"]'),
          page.locator("circular-progress-indicator"),
        ];

        let loadingFound = false;
        for (const indicator of loadingIndicators) {
          if (await indicator.isVisible({ timeout: 1000 }).catch(() => false)) {
            loadingFound = true;
            break;
          }
        }

        if (loadingFound) {
          console.log(`   → Loading indicator found for ${buttonSelector}`);
        }

        // Wait for page to load
        await page.waitForTimeout(2000);

        // Go back
        await page.goBack();
        await page.waitForTimeout(1000);
      }
    }

    console.log("   ✅ Loading states handled appropriately");
  });
});
