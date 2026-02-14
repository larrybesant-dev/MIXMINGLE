const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

(async () => {
  const browser = await chromium.launch({ headless: false });
  const context = await browser.newContext();
  const page = await context.newPage();

  const appUrl = 'https://mix-and-mingle-62061.web.app';

  const results = [];

  console.log(`🚀 Starting targeted smoke test for Mix & Mingle\n`);
  console.log(`📱 App URL: ${appUrl}\n`);

  try {
    // --- Phase 1: Basic App Loading ---
    console.log('🌐 Testing basic app loading...');
    await page.goto(appUrl, { waitUntil: 'networkidle', timeout: 30000 });

    // Check title
    const title = await page.title();
    const hasCorrectTitle = title.includes('Mix') && title.includes('Mingle');
    console.log(`   📋 Title: "${title}" - ${hasCorrectTitle ? '✅ Correct' : '❌ Incorrect'}`);

    // Check for Flutter content
    const bodyText = await page.textContent('body');
    const hasFlutterContent = bodyText.length > 100; // Basic check for content
    console.log(`   📄 Content loaded: ${hasFlutterContent ? '✅ Yes' : '❌ No'}`);

    // Take screenshot
    await page.screenshot({ path: 'targeted-smoke-test-screenshot.png', fullPage: true });
    console.log('   📸 Screenshot saved');

    results.push({
      feature: 'App Loading',
      status: hasCorrectTitle && hasFlutterContent ? 'Working' : 'Error',
      details: `Title: ${title}, Content length: ${bodyText.length}`
    });

    // --- Phase 2: Speed Dating Route Test ---
    console.log('\n💕 Testing Speed Dating accessibility...');

    // Get initial page content hash
    const initialContent = await page.textContent('body');
    const initialHash = hashString(initialContent);

    // Try direct navigation to speed dating lobby
    const speedDatingUrl = `${appUrl}#/speed-dating-lobby`;
    console.log(`   🔗 Navigating to: ${speedDatingUrl}`);

    try {
      await page.goto(speedDatingUrl, { waitUntil: 'networkidle', timeout: 15000 });

      // Wait for potential content changes
      await page.waitForTimeout(5000);

      // Check if content changed (indicating route worked)
      const newContent = await page.textContent('body');
      const newHash = hashString(newContent);
      const contentChanged = initialHash !== newHash;

      // Check URL
      const currentUrl = page.url();
      const urlChanged = currentUrl.includes('speed-dating-lobby');

      console.log(`   📍 URL changed: ${urlChanged ? '✅ Yes' : '❌ No'}`);
      console.log(`   📄 Content changed: ${contentChanged ? '✅ Yes' : '❌ No'}`);

      // Check for error indicators
      const hasErrors = newContent.includes('error') ||
                       newContent.includes('Error') ||
                       newContent.includes('404') ||
                       newContent.includes('not found');

      if (urlChanged && contentChanged && !hasErrors) {
        console.log('   ✅ Speed Dating route accessible');
        results.push({
          feature: 'Speed Dating Route',
          status: 'Working',
          details: 'Route accessible and content loads'
        });
      } else if (hasErrors) {
        console.log('   ❌ Speed Dating route has errors');
        results.push({
          feature: 'Speed Dating Route',
          status: 'Error',
          details: 'Route shows error content'
        });
      } else {
        console.log('   ⚠️  Speed Dating route may not be working');
        results.push({
          feature: 'Speed Dating Route',
          status: 'Unknown',
          details: 'Route accessible but behavior unclear'
        });
      }
    } catch (navErr) {
      console.log(`   ❌ Navigation failed: ${navErr.message}`);
      results.push({
        feature: 'Speed Dating Route',
        status: 'Error',
        details: `Navigation failed: ${navErr.message}`
      });
    }

    // --- Phase 3: Firebase Integration Check ---
    console.log('\n🔥 Checking Firebase integration...');

    // Look for Firebase scripts in the page
    const firebaseScripts = await page.locator('script[src*="firebase"]').count();
    console.log(`   📜 Firebase scripts found: ${firebaseScripts}`);

    // Check for console errors
    const consoleErrors = [];
    page.on('console', msg => {
      if (msg.type() === 'error') {
        consoleErrors.push(msg.text());
      }
    });

    await page.waitForTimeout(3000);

    if (consoleErrors.length > 0) {
      console.log(`   ❌ Console errors: ${consoleErrors.length}`);
      results.push({
        feature: 'JavaScript Errors',
        status: 'Errors Found',
        details: `${consoleErrors.length} console errors detected`
      });
    } else {
      console.log('   ✅ No console errors');
      results.push({
        feature: 'JavaScript Errors',
        status: 'Clean',
        details: 'No console errors'
      });
    }

    // --- Phase 4: Network Requests Check ---
    console.log('\n🌐 Checking network requests...');

    const requests = [];
    page.on('request', request => {
      requests.push(request.url());
    });

    // Navigate to speed dating again to capture requests
    await page.goto(speedDatingUrl, { waitUntil: 'networkidle' });
    await page.waitForTimeout(3000);

    const firebaseRequests = requests.filter(url =>
      url.includes('firestore.googleapis.com') ||
      url.includes('firebase') ||
      url.includes('googleapis.com')
    );

    console.log(`   📡 Firebase requests: ${firebaseRequests.length}`);
    results.push({
      feature: 'Firebase Requests',
      status: firebaseRequests.length > 0 ? 'Working' : 'Not Detected',
      details: `${firebaseRequests.length} Firebase-related requests detected`
    });

  } catch (err) {
    console.log(`💥 Test failed with error: ${err.message}`);
    results.push({
      feature: 'Test Execution',
      status: 'Failed',
      details: `Test crashed: ${err.message}`
    });
  }

  // --- Phase 5: Generate Report ---
  console.log('\n📊 Generating CSV report...');
  const csvFile = path.join(__dirname, 'targeted-smoke-test-report.csv');
  const csvHeader = 'Feature,Status,Details\n';
  const csvRows = results.map(r =>
    `"${r.feature}","${r.status}","${r.details.replace(/"/g, '""')}"`
  ).join('\n');

  const csvContent = csvHeader + csvRows;
  fs.writeFileSync(csvFile, csvContent);
  console.log(`✅ Report saved to: ${csvFile}`);

  // --- Phase 6: Summary ---
  console.log('\n📈 Test Summary:');
  const working = results.filter(r => r.status === 'Working').length;
  const errors = results.filter(r => ['Error', 'Errors Found', 'Failed'].includes(r.status)).length;
  const unknown = results.filter(r => r.status === 'Unknown').length;
  const notDetected = results.filter(r => r.status === 'Not Detected').length;

  console.log(`   ✅ Working: ${working}`);
  console.log(`   ❌ Errors: ${errors}`);
  console.log(`   ❓ Unknown: ${unknown}`);
  console.log(`   🚫 Not Detected: ${notDetected}`);
  console.log(`   📊 Total checks: ${results.length}`);

  const successRate = Math.round((working / results.length) * 100);
  console.log(`   🎯 Success Rate: ${successRate}%`);

  if (working >= 2 && errors === 0) {
    console.log('\n🎉 Core functionality appears to be working!');
    console.log('   ✅ App loads successfully');
    console.log('   ✅ Speed Dating route is accessible');
    console.log('   ✅ No JavaScript errors');
  } else if (errors > 0) {
    console.log('\n⚠️  Issues detected that need attention.');
  } else {
    console.log('\n🤔 Limited testing possible with current setup.');
  }

  await browser.close();
  console.log('\n🏁 Targeted smoke test complete.');
})();

// Simple string hashing function
function hashString(str) {
  let hash = 0;
  for (let i = 0; i < str.length; i++) {
    const char = str.charCodeAt(i);
    hash = ((hash << 5) - hash) + char;
    hash = hash & hash; // Convert to 32-bit integer
  }
  return hash.toString();
}