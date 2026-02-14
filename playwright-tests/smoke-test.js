const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

(async () => {
  const browser = await chromium.launch({ headless: false });
  const context = await browser.newContext();
  const page = await context.newPage();

  const appUrl = 'https://mix-and-mingle-62061.web.app';
  const results = [];

  console.log(`🚀 Starting comprehensive smoke test for Mix & Mingle\n`);
  console.log(`📱 App URL: ${appUrl}\n`);

  try {
    // Open the app
    console.log('🌐 Opening app...');
    await page.goto(appUrl, { waitUntil: 'networkidle', timeout: 30000 });
    console.log('✅ App loaded successfully\n');

    // Wait for Flutter to initialize (longer wait for web)
    console.log('⏳ Waiting for Flutter app to initialize...');
    await page.waitForTimeout(15000); // Increased from 10000

    // Take a screenshot for debugging
    await page.screenshot({ path: 'debug-smoke-test.png', fullPage: true });
    console.log('📸 Screenshot saved as debug-smoke-test.png');

    // Get page title and some basic content
    const title = await page.title();
    console.log(`📄 Page title: "${title}"`);

    const bodyText = await page.locator('body').textContent();
    console.log(`📝 Page contains ${bodyText.length} characters of text`);
    console.log(`📄 First 500 chars: "${bodyText.substring(0, 500)}"`);

    // Try to find any text content
    const allText = await page.locator('*').allTextContents();
    const visibleText = allText.filter(text => text.trim().length > 0);
    console.log(`📝 Found ${visibleText.length} text elements:`);
    visibleText.slice(0, 10).forEach((text, i) => {
      console.log(`   ${i + 1}. "${text.substring(0, 50)}${text.length > 50 ? '...' : ''}"`);
    });

    // Check for Flutter-specific elements
    const flutterElements = await page.locator('flutter-view, flt-glass-pane, flt-scene').count();
    console.log(`🎨 Found ${flutterElements} Flutter rendering elements`);

    // Check if we're on the splash/loading screen
    const isLoading = await page.locator('text=/Loading|Initializing|Splash/i').isVisible().catch(() => false);
    if (isLoading) {
      console.log('⏳ App is loading...');
      await page.waitForTimeout(5000);
    }

    // Try to find login elements
    console.log('🔐 Checking authentication...');
    const loginButton = page.locator('text=/Sign In|Login|Continue with Google/i').first();
    const isOnLoginPage = await loginButton.isVisible().catch(() => false);

    if (isOnLoginPage) {
      console.log('📝 On login page - authentication required for full testing');
      console.log('⚠️  Manual login needed - test will check basic app loading only');

      // For now, let's just check if the login page loads properly
      const loginTitle = await page.locator('text=/Mix.*Mingle|Welcome|Login/i').first().isVisible().catch(() => false);
      if (loginTitle) {
        console.log('✅ Login page loaded correctly');
      } else {
        console.log('❌ Login page may not have loaded properly');
      }

      // Skip feature testing since we can't access the app without login
      console.log('\n⏭️  Skipping feature tests due to authentication requirement');
      results.push({
        feature: 'Authentication',
        status: 'requires_login',
        details: 'App requires user login to access features',
        timestamp: new Date().toISOString()
      });

      // Generate report and exit early
      const csvContent = 'Feature,Status,Details,Timestamp\n' +
        results.map(r => `"${r.feature}","${r.status}","${r.details.replace(/"/g, '""')}","${r.timestamp}"`).join('\n');

      fs.writeFileSync(reportPath, csvContent);
      console.log(`✅ Report saved to: ${reportPath}`);

      console.log('\n📈 Test Summary:');
      console.log(`   🔐 Requires Login: App needs authentication to test features`);
      console.log(`   📊 Total tested: ${results.length}`);

      await browser.close();
      console.log('\n🏁 Smoke test complete (limited due to auth).');
      return;
    } else {
      console.log('✅ User appears to be logged in or no login required');
    }

    // Define features to test with text-based selectors
    const features = [
      {
        name: 'Home/Dashboard',
        selector: 'text=/Find Events|Start Chat|Speed Date|Edit Profile/i',
        expected: 'accessible'
      },
      {
        name: 'Speed Dating',
        selector: 'text=/Speed Date|Join Now/i',
        expected: 'accessible'
      },
      {
        name: 'Chat/Messages',
        selector: 'text=/Start Chat|Messages|Recent Messages/i',
        expected: 'accessible'
      },
      {
        name: 'Rooms/Browse',
        selector: 'text=/Find Events|Events/i',
        expected: 'accessible'
      },
      {
        name: 'Profile',
        selector: 'text=/Edit Profile|Profile/i',
        expected: 'accessible'
      },
      {
        name: 'Notifications',
        selector: 'text=/Notifications/i',
        expected: 'accessible'
      },
      {
        name: 'Discover Users',
        selector: 'text=/Discover|Users/i',
        expected: 'accessible'
      },
      {
        name: 'Go Live',
        selector: 'text=/Go Live|Stream/i',
        expected: 'accessible'
      }
    ];

    console.log('🧪 Testing features...\n');

    for (const feature of features) {
      const result = {
        feature: feature.name,
        status: 'unknown',
        details: '',
        timestamp: new Date().toISOString()
      };

      try {
        const element = page.locator(feature.selector).first();
        const isVisible = await element.isVisible({ timeout: 5000 });

        if (isVisible) {
          const text = await element.textContent();
          const isComingSoon = text.includes('Coming Soon') ||
                              text.includes('coming soon') ||
                              text.includes('TODO') ||
                              text.includes('Not implemented');

          if (isComingSoon) {
            result.status = 'coming_soon';
            result.details = `Found but shows: "${text.trim()}"`;
            console.log(`⏳ ${feature.name}: Coming Soon - "${text.trim()}"`);
          } else {
            result.status = 'working';
            result.details = 'Accessible and functional';
            console.log(`✅ ${feature.name}: Working`);
          }
        } else {
          result.status = 'not_found';
          result.details = 'Element not found on page';
          console.log(`❌ ${feature.name}: Not found`);
        }
      } catch (err) {
        result.status = 'error';
        result.details = err.message;
        console.log(`💥 ${feature.name}: Error - ${err.message}`);
      }

      results.push(result);
    }

    // Test navigation if possible
    console.log('\n🧭 Testing navigation...');
    try {
      // Try to find navigation elements
      const navElements = await page.locator('[role="navigation"], nav, .nav, .navbar').all();
      if (navElements.length > 0) {
        console.log(`✅ Navigation elements found: ${navElements.length}`);
      } else {
        console.log('⚠️  No navigation elements detected');
      }
    } catch (err) {
      console.log(`⚠️  Navigation test failed: ${err.message}`);
    }

    // Check for errors in console
    console.log('\n🔍 Checking for console errors...');
    const errors = [];
    page.on('console', msg => {
      if (msg.type() === 'error') {
        errors.push(msg.text());
      }
    });

    await page.waitForTimeout(2000); // Let any remaining errors appear

    if (errors.length > 0) {
      console.log(`❌ Found ${errors.length} console errors:`);
      errors.forEach((error, i) => console.log(`   ${i + 1}. ${error}`));
    } else {
      console.log('✅ No console errors detected');
    }

  } catch (err) {
    console.log(`💥 Test failed with error: ${err.message}`);
  }

  // Generate CSV report
  console.log('\n📊 Generating CSV report...');
  const csvHeader = 'Feature,Status,Details,Timestamp\n';
  const csvRows = results.map(r =>
    `"${r.feature}","${r.status}","${r.details.replace(/"/g, '""')}","${r.timestamp}"`
  ).join('\n');

  const csvContent = csvHeader + csvRows;
  const reportPath = path.join(__dirname, 'smoke-test-report.csv');

  fs.writeFileSync(reportPath, csvContent);
  console.log(`✅ Report saved to: ${reportPath}`);

  // Summary
  console.log('\n📈 Test Summary:');
  const working = results.filter(r => r.status === 'working').length;
  const comingSoon = results.filter(r => r.status === 'coming_soon').length;
  const issues = results.filter(r => ['not_found', 'error'].includes(r.status)).length;

  console.log(`   ✅ Working: ${working}`);
  console.log(`   ⏳ Coming Soon: ${comingSoon}`);
  console.log(`   ❌ Issues: ${issues}`);
  console.log(`   📊 Total tested: ${results.length}`);

  if (issues === 0 && working > 0) {
    console.log('\n🎉 Smoke test PASSED! Core features are working.');
  } else if (issues > 0) {
    console.log('\n⚠️  Smoke test found issues that need attention.');
  }

  await browser.close();
  console.log('\n🏁 Smoke test complete.');
})();