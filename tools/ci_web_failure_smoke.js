const fs = require('fs/promises');
const path = require('path');
const { chromium } = require('playwright');

const APP_URL = process.env.STARTUP_APP_URL || 'http://127.0.0.1:8080/';
const REPORT_PATH = process.env.WEB_SMOKE_REPORT_PATH || 'tools/reports/web_failure_smoke_report.json';

const FLUTTER_SURFACE_SELECTOR = 'flt-glass-pane, flutter-view, flt-scene-host';

async function waitForUiFallbackOrSurface(page, timeoutMs) {
  const started = Date.now();
  const initialBootMsg = await page
    .$eval('#boot-msg', (el) => (el.textContent || '').trim())
    .catch(() => '');

  while (Date.now() - started < timeoutMs) {
    const hasSurface = await page.$(FLUTTER_SURFACE_SELECTOR);
    if (hasSurface) {
      return { mode: 'flutter-surface' };
    }

    const bootMessage = await page
      .$eval('#boot-msg', (el) => (el.textContent || '').trim())
      .catch(() => '');

    if (
      bootMessage &&
      (bootMessage !== initialBootMsg ||
        bootMessage.includes('Unable to load app runtime') ||
        bootMessage.includes('Still loading'))
    ) {
      return { mode: 'fallback', bootMessage };
    }

    await page.waitForTimeout(250);
  }

  throw new Error('UI did not reach Flutter surface or fallback state within timeout');
}

async function runSlow3gScenario(browser) {
  const context = await browser.newContext();
  const page = await context.newPage();
  const cdp = await context.newCDPSession(page);
  await cdp.send('Network.enable');
  await cdp.send('Network.emulateNetworkConditions', {
    offline: false,
    latency: 400,
    downloadThroughput: 50000,
    uploadThroughput: 20000,
    connectionType: 'cellular3g',
  });

  await page.goto(APP_URL, { waitUntil: 'domcontentloaded', timeout: 45000 });
  const state = await waitForUiFallbackOrSurface(page, 45000);
  await context.close();
  return state;
}

async function runOfflineScenario(browser) {
  const context = await browser.newContext();
  await context.setOffline(true);
  const page = await context.newPage();

  try {
    await page.goto(APP_URL, { waitUntil: 'domcontentloaded', timeout: 15000 });
  } catch (_) {
    // Navigation can fail while offline; fallback UI state is still the target.
  }

  const state = await waitForUiFallbackOrSurface(page, 20000);
  await context.close();
  return state;
}

async function runFirebaseTimeoutScenario(browser) {
  const context = await browser.newContext();
  const page = await context.newPage();

  await page.route('**/*', async (route) => {
    const url = route.request().url();
    if (
      url.includes('googleapis.com') ||
      url.includes('firebaseinstallations.googleapis.com') ||
      url.includes('firestore.googleapis.com')
    ) {
      await route.abort('timedout');
      return;
    }
    await route.continue();
  });

  await page.goto(APP_URL, { waitUntil: 'domcontentloaded', timeout: 30000 });
  const state = await waitForUiFallbackOrSurface(page, 30000);
  await context.close();
  return state;
}

async function runReconnectScenario(browser) {
  const context = await browser.newContext();
  const page = await context.newPage();

  await page.goto(APP_URL, { waitUntil: 'domcontentloaded', timeout: 30000 });
  await waitForUiFallbackOrSurface(page, 30000);

  await context.setOffline(true);
  await page.waitForTimeout(1200);
  await context.setOffline(false);

  await page.reload({ waitUntil: 'domcontentloaded', timeout: 30000 });
  const state = await waitForUiFallbackOrSurface(page, 30000);
  await context.close();
  return state;
}

async function runScenario(name, fn) {
  const started = Date.now();
  try {
    const result = await fn();
    return {
      name,
      status: 'PASS',
      durationMs: Date.now() - started,
      result,
    };
  } catch (error) {
    return {
      name,
      status: 'FAIL',
      durationMs: Date.now() - started,
      error: error && error.message ? error.message : String(error),
    };
  }
}

async function main() {
  const browser = await chromium.launch({ headless: true });

  const scenarios = [];
  scenarios.push(await runScenario('slow_3g_startup', () => runSlow3gScenario(browser)));
  scenarios.push(await runScenario('offline_launch_fallback', () => runOfflineScenario(browser)));
  scenarios.push(await runScenario('firebase_timeout_fallback', () => runFirebaseTimeoutScenario(browser)));
  scenarios.push(await runScenario('reconnect_reload_recovery', () => runReconnectScenario(browser)));

  await browser.close();

  const report = {
    generatedAt: new Date().toISOString(),
    appUrl: APP_URL,
    scenarios,
  };

  await fs.mkdir(path.dirname(REPORT_PATH), { recursive: true });
  await fs.writeFile(REPORT_PATH, `${JSON.stringify(report, null, 2)}\n`, 'utf8');

  const failed = scenarios.filter((s) => s.status !== 'PASS');
  if (failed.length > 0) {
    throw new Error(`Web failure smoke suite failed scenarios: ${failed.map((s) => s.name).join(', ')}`);
  }

  console.log(`Web failure smoke suite passed. Report: ${REPORT_PATH}`);
}

main().catch((error) => {
  console.error(error && error.stack ? error.stack : error);
  process.exit(1);
});
