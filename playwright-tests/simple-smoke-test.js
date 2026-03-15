const { chromium } = require("playwright");

(async () => {
  const browser = await chromium.launch({ headless: false });
  const context = await browser.newContext();
  const page = await context.newPage();

  const appUrl = "https://mix-and-mingle-62061.web.app";

  console.log(`🚀 Starting smoke test for Mix & Mingle Flutter Web App\n`);
  console.log(`📱 App URL: ${appUrl}\n`);

  try {
    // Open the app
    console.log("🌐 Opening app...");
    await page.goto(appUrl, { waitUntil: "networkidle", timeout: 30000 });
    console.log("✅ App loaded successfully\n");

    // Wait for Flutter to initialize
    console.log("⏳ Waiting for Flutter app to initialize...");
    await page.waitForTimeout(10000);

    // Take a screenshot for debugging
    await page.screenshot({ path: "smoke-test-screenshot.png", fullPage: true });
    console.log("📸 Screenshot saved as smoke-test-screenshot.png");

    // Basic health checks
    const title = await page.title();
    console.log(`📄 Page title: "${title}"`);

    const hasTitle = title.includes("Mix & Mingle");
    console.log(`${hasTitle ? "✅" : "❌"} Title check: ${hasTitle ? "Correct" : "Incorrect"}`);

    // Check for Flutter-specific elements
    const flutterView = await page.locator("flutter-view").count();
    console.log(
      `${flutterView > 0 ? "✅" : "❌"} Flutter view: ${flutterView > 0 ? "Present" : "Missing"}`,
    );

    // Check for Firebase scripts
    const firebaseScripts = await page.locator('script[src*="firebase"]').count();
    console.log(`${firebaseScripts > 0 ? "✅" : "❌"} Firebase scripts: ${firebaseScripts} found`);

    // Check for basic HTML structure
    const bodyExists = await page.locator("body").isVisible();
    console.log(`${bodyExists ? "✅" : "❌"} HTML body: ${bodyExists ? "Present" : "Missing"}`);

    // Check for console errors
    console.log("\n🔍 Checking for console errors...");
    const errors = [];
    page.on("console", (msg) => {
      if (msg.type() === "error") {
        errors.push(msg.text());
      }
    });

    await page.waitForTimeout(3000); // Let any errors appear

    if (errors.length > 0) {
      console.log(`❌ Found ${errors.length} console errors:`);
      errors.forEach((error, i) => console.log(`   ${i + 1}. ${error}`));
    } else {
      console.log("✅ No console errors detected");
    }

    // Summary
    console.log("\n📈 Smoke Test Results:");
    const allChecks = [
      hasTitle,
      flutterView > 0,
      firebaseScripts > 0,
      bodyExists,
      errors.length === 0,
    ];

    const passed = allChecks.filter(Boolean).length;
    const total = allChecks.length;

    console.log(`   ✅ Passed: ${passed}/${total}`);
    console.log(`   📊 Success Rate: ${Math.round((passed / total) * 100)}%`);

    if (passed === total) {
      console.log("\n🎉 SMOKE TEST PASSED! App loads successfully.");
      console.log("\n📝 Manual Testing Required:");
      console.log("   Since this is a Flutter Web app, automated UI testing is limited.");
      console.log("   Please manually test the following features:");
      console.log("   • Speed Dating: Join lobby, match with users, video chat");
      console.log("   • Navigation: All app bar icons work");
      console.log("   • Authentication: Login/logout flow");
      console.log("   • Core Features: Rooms, messages, profile, etc.");
    } else {
      console.log("\n⚠️  SMOKE TEST ISSUES DETECTED");
      console.log("   The app may have loading or initialization problems.");
    }
  } catch (err) {
    console.log(`💥 Test failed with error: ${err.message}`);
  }

  await browser.close();
  console.log("\n🏁 Smoke test complete.");
})();
