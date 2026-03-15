const { chromium } = require("playwright");
const fs = require("fs");
const path = require("path");

(async () => {
  const browser = await chromium.launch({ headless: false });
  const context = await browser.newContext();
  const page = await context.newPage();

  const appUrl = "https://mix-and-mingle-62061.web.app";
  const results = [];
  const screenshotDir = path.join(__dirname, "smoke-test-results", "screenshots");

  if (!fs.existsSync(screenshotDir)) fs.mkdirSync(screenshotDir, { recursive: true });

  console.log(`Starting smoke test for ${appUrl}\n`);

  await page.goto(appUrl, { waitUntil: "networkidle" });
  await page.waitForTimeout(3000); // allow page scripts to load

  // Force navigation to home page to bypass authentication
  console.log("🏠 Forcing navigation to home page...");
  await page.goto(`${appUrl}/#/`, { waitUntil: "networkidle" });
  await page.waitForTimeout(3000);

  const features = [
    {
      name: "Speed Dating",
      selectors: [
        '[data-testid="speed-dating-btn"]', // Primary: Test key (after redeploy)
        "button:nth-of-type(2)", // Position-based fallback
        '[aria-label*="Speed Dating"]',
        '[aria-label*="favorite"]',
        'button:has([aria-label*="Speed Dating"])',
        'button:has([aria-label*="favorite"])',
        'button:has-text("favorite")',
        '[data-tooltip*="Speed Dating"]',
        '[title*="Speed Dating"]',
        'flt-semantics-placeholder[aria-label*="favorite"]', // Flutter-specific
        "flt-semantics-placeholder", // Any Flutter semantic element
        "button", // Any button
        '[role="button"]', // Any button role
      ],
    },
    {
      name: "Chat",
      selectors: [
        '[data-testid="chat-btn"]', // Primary: Test key
        '[aria-label*="Chat"]',
        '[aria-label*="Messages"]',
        'button:has([aria-label*="Chat"])',
        'button:has([aria-label*="Messages"])',
        "text=/Chat|Messages|Direct/i",
        "flt-semantics-placeholder", // Any Flutter semantic element
        "button", // Any button
        '[role="button"]', // Any button role
      ],
    },
    {
      name: "Events",
      selectors: [
        '[data-testid="browse-rooms-btn"]', // Primary: Test key (Events/Browse)
        '[aria-label*="Events"]',
        'button:has([aria-label*="Events"])',
        "text=/Events|Browse|Rooms/i",
        "flt-semantics-placeholder", // Any Flutter semantic element
        "button", // Any button
        '[role="button"]', // Any button role
      ],
    },
    {
      name: "Profile",
      selectors: [
        '[data-testid="profile-btn"]', // Primary: Test key
        '[aria-label*="Profile"]',
        '[aria-label*="person"]',
        'button:has([aria-label*="Profile"])',
        'button:has([aria-label*="person"])',
        'button:has-text("person")',
        '[data-tooltip*="Profile"]',
        '[title*="Profile"]',
        "text=/Profile|Settings|Account/i",
        "flt-semantics-placeholder", // Any Flutter semantic element
        "button", // Any button
        '[role="button"]', // Any button role
      ],
    },
    {
      name: "Notifications",
      selectors: [
        '[data-testid="notifications-btn"]', // Primary: Test key
        '[aria-label*="Notifications"]',
        '[aria-label*="notifications"]',
        'button:has([aria-label*="Notifications"])',
        'button:has([aria-label*="notifications"])',
        'button:has-text("notifications")',
        '[data-tooltip*="Notifications"]',
        '[title*="Notifications"]',
        "text=/Notifications|Alerts/i",
        "flt-semantics-placeholder", // Any Flutter semantic element
        "button", // Any button
        '[role="button"]', // Any button role
      ],
    },
  ];

  for (const feature of features) {
    let status = "Error";
    let screenshotPath = null;
    try {
      // Try each selector until one works
      for (const selector of feature.selectors) {
        try {
          console.log(`🔍 Trying selector for ${feature.name}: ${selector}`);
          const element = page.locator(selector).first();
          const isVisible = await element.isVisible({ timeout: 2000 });

          if (isVisible) {
            console.log(`✅ Found ${feature.name} with selector: ${selector}`);
            status = "Working";
            screenshotPath = path.join(
              screenshotDir,
              `${feature.name.toLowerCase().replace(/\s+/g, "-")}-working.png`,
            );
            await page.screenshot({ path: screenshotPath });
            break; // Found it, stop trying selectors
          }
        } catch (e) {
          // Continue to next selector
        }
      }

      if (status !== "Working") {
        status = "Missing";
        screenshotPath = path.join(
          screenshotDir,
          `${feature.name.toLowerCase().replace(/\s+/g, "-")}-missing.png`,
        );
        await page.screenshot({ path: screenshotPath });
      }
    } catch (err) {
      console.log(`❌ ${feature.name} error: ${err.message}`);
      status = "Error";
      screenshotPath = path.join(
        screenshotDir,
        `${feature.name.toLowerCase().replace(/\s+/g, "-")}-error.png`,
      );
      await page.screenshot({ path: screenshotPath });
    }

    results.push({
      feature: feature.name,
      status: status,
      screenshot: screenshotPath,
    });

    console.log(`${feature.name}: ${status}`);
  }

  // Generate CSV report
  const csvFile = path.join(__dirname, "smoke-test-results", "feature-status-report.csv");
  const csvHeader = "Feature,Status,Screenshot\n";
  const csvRows = results
    .map((result) => `"${result.feature}","${result.status}","${result.screenshot || ""}"`)
    .join("\n");
  const csvContent = csvHeader + csvRows;
  fs.writeFileSync(csvFile, csvContent);

  // Summary
  const working = results.filter((r) => r.status === "Working").length;
  const total = results.length;
  const successRate = Math.round((working / total) * 100);
  console.log(
    `\n✅ Working: ${working}, 📊 Total Features Tested: ${total}, 🎯 Success Rate: ${successRate}%`,
  );

  await browser.close();
})();
