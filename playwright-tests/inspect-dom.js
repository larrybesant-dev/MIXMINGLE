const { chromium } = require("playwright");

(async () => {
  const browser = await chromium.launch({ headless: false });
  const page = await browser.newPage();

  // Capture console messages
  const consoleMessages = [];
  page.on("console", (msg) => {
    consoleMessages.push(`${msg.type()}: ${msg.text()}`);
  });

  page.on("pageerror", (error) => {
    consoleMessages.push(`Page Error: ${error.message}`);
  });

  console.log("Loading Mix & Mingle...");
  await page.goto("https://mix-and-mingle-62061.web.app?test", { waitUntil: "networkidle" });
  await page.waitForTimeout(15000);

  console.log("Console messages:");
  consoleMessages.forEach((msg) => console.log("  ", msg));

  console.log("Page title:", await page.title());
  console.log("URL:", page.url());

  // Check if we're on home page now
  if (!page.url().includes("/login")) {
    console.log("✅ Successfully bypassed authentication - on main app");
  } else {
    console.log("❌ Still on login page - authentication bypass failed");
  }

  // Check if Flutter loaded
  const flutterElements = await page
    .locator("flt-glass-pane, flt-semantics-placeholder, [data-semantic]")
    .all();
  console.log(`Found ${flutterElements.length} Flutter elements`);

  // Check for login elements
  const loginElements = await page
    .locator(
      'input[type="email"], input[type="password"], button:has-text("Sign"), button:has-text("Login")',
    )
    .all();
  console.log(`Found ${loginElements.length} login elements`);

  // Check for navigation elements
  const navElements = await page.locator('button, [role="button"]').all();
  console.log(`Found ${navElements.length} navigation elements`);

  // Try to find any text content
  const bodyText = await page.textContent("body");
  console.log("Body text length:", bodyText?.length || 0);
  console.log("Body text preview:", bodyText?.substring(0, 500) + "...");

  console.log("Inspecting DOM for buttons...");

  // Get all button-like elements
  const buttons = await page
    .locator(
      'button, [role="button"], input[type="button"], a, flt-semantics-placeholder[role="button"]',
    )
    .all();
  console.log(`Found ${buttons.length} button-like elements`);

  for (let i = 0; i < Math.min(buttons.length, 10); i++) {
    const button = buttons[i];
    const tagName = await button.evaluate((el) => el.tagName);
    const text = await button.textContent();
    const attributes = await button.evaluate((el) => {
      const attrs = {};
      for (let attr of el.attributes) {
        attrs[attr.name] = attr.value;
      }
      return attrs;
    });

    console.log(`Button ${i + 1}:`);
    console.log(`  Tag: ${tagName}`);
    console.log(`  Text: "${text?.trim()}"`);
    console.log(`  Attributes:`, JSON.stringify(attributes, null, 2));
    console.log("---");
  }

  // Look for any elements with Keys
  const keyElements = await page
    .locator('[id*="key"], [class*="key"], [data-testid], [aria-label]')
    .all();
  console.log(`Found ${keyElements.length} elements with potential key attributes`);

  for (let i = 0; i < Math.min(keyElements.length, 5); i++) {
    const element = keyElements[i];
    const tagName = await element.evaluate((el) => el.tagName);
    const attributes = await element.evaluate((el) => {
      const attrs = {};
      for (let attr of el.attributes) {
        attrs[attr.name] = attr.value;
      }
      return attrs;
    });

    console.log(`Key element ${i + 1}:`);
    console.log(`  Tag: ${tagName}`);
    console.log(`  Attributes:`, JSON.stringify(attributes, null, 2));
    console.log("---");
  }

  await browser.close();
})();
