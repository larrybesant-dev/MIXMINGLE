const fs = require('fs/promises');
const path = require('path');
const { chromium } = require('playwright');

const APP_URL = process.env.STARTUP_APP_URL || 'http://127.0.0.1:8080/';
const OUTPUT_PATH = process.env.STARTUP_LOG_PATH || 'tools/reports/startup_timeline.log';
const CAPTURE_TIMEOUT_MS = Number(process.env.STARTUP_CAPTURE_TIMEOUT_MS || '45000');
const APP_READY_TIMEOUT_MS = Number(process.env.STARTUP_APP_READY_TIMEOUT_MS || '30000');
const LOG_POLL_TIMEOUT_MS = Number(process.env.STARTUP_LOG_POLL_TIMEOUT_MS || '15000');

const REQUIRED = [
  'mainStart',
  'bindingReady',
  'firebaseReady',
  'bootstrapResolved',
  'firstFrameRendered',
];

const WINDOW_TIMELINE_KEY = 'startupLogs';

function extractStartupLine(text) {
  const match = text.match(/(\+\d+ms startup\.[A-Za-z0-9_]+(?:\s+[^\r\n]*)?)/);
  return match ? match[1].trim() : null;
}

function checkpointFromLine(line) {
  const match = line.match(/startup\.([A-Za-z0-9_]+)/);
  return match ? match[1] : null;
}

async function main() {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();

  const byCheckpoint = new Map();
  const consoleSamples = [];
  const pageErrors = [];
  const requestFailures = [];
  const responseSamples = [];

  page.on('console', (msg) => {
    if (consoleSamples.length < 20) {
      consoleSamples.push(`${msg.type()}: ${msg.text()}`);
    }

    const line = extractStartupLine(msg.text());
    if (!line) return;
    const checkpoint = checkpointFromLine(line);
    if (!checkpoint) return;
    if (!byCheckpoint.has(checkpoint)) {
      byCheckpoint.set(checkpoint, line);
    }
  });

  page.on('pageerror', (error) => {
    if (pageErrors.length < 20) {
      pageErrors.push(error && error.message ? error.message : String(error));
    }
  });

  page.on('requestfailed', (request) => {
    if (requestFailures.length < 30) {
      requestFailures.push({
        url: request.url(),
        method: request.method(),
        errorText: request.failure() ? request.failure().errorText : 'unknown',
      });
    }
  });

  page.on('response', (response) => {
    if (responseSamples.length < 30) {
      responseSamples.push({
        url: response.url(),
        status: response.status(),
      });
    }
  });

  await page.goto(APP_URL, { waitUntil: 'domcontentloaded', timeout: CAPTURE_TIMEOUT_MS });

  await page.waitForFunction(
    () => {
      const hasFlutterSurface = Boolean(
        document.querySelector('flt-glass-pane, flutter-view, flt-scene-host'),
      );
      const hasBootShell = Boolean(document.querySelector('#boot-shell'));
      const hasBootstrapScript = Array.from(document.scripts).some((script) =>
        (script.src || '').includes('flutter_bootstrap.js'),
      );
      const hasFlutterRuntime = Boolean(window._flutter || window.flutter);
      return hasFlutterSurface || hasBootShell || hasBootstrapScript || hasFlutterRuntime;
    },
    { timeout: APP_READY_TIMEOUT_MS },
  );

  const startedAt = Date.now();
  while (Date.now() - startedAt < LOG_POLL_TIMEOUT_MS) {
    const runtimeLines = await page.evaluate((key) => {
      const value = window.sessionStorage.getItem(key);
      if (!value) return [];
      return value
        .split(/\r?\n/)
        .map((line) => line.trim())
        .filter(Boolean);
    }, WINDOW_TIMELINE_KEY);

    for (const line of runtimeLines) {
      const checkpoint = checkpointFromLine(line);
      if (!checkpoint) continue;
      if (!byCheckpoint.has(checkpoint)) {
        byCheckpoint.set(checkpoint, line);
      }
    }

    const hasAll = REQUIRED.every((cp) => byCheckpoint.has(cp));
    if (hasAll) break;
    await page.waitForTimeout(250);
  }

  const missing = REQUIRED.filter((cp) => !byCheckpoint.has(cp));
  if (missing.length > 0) {
    const bootState = await page
      .evaluate(() => ({
        title: document.title,
        bootMessage: document.querySelector('#boot-msg')?.textContent || '',
        hasFlutterSurface: Boolean(
          document.querySelector('flt-glass-pane, flutter-view, flt-scene-host'),
        ),
        hasFlutterRuntime: Boolean(window._flutter || window.flutter),
        startupLogs: window.sessionStorage.getItem('startupLogs') || '',
      }))
      .catch(() => null);

    throw new Error(
      `Missing startup checkpoints from real runtime console: ${missing.join(', ')}\n` +
          `bootState=${JSON.stringify(bootState)}\n` +
          `pageErrors=${JSON.stringify(pageErrors)}\n` +
          `requestFailures=${JSON.stringify(requestFailures)}\n` +
          `responseSamples=${JSON.stringify(responseSamples)}\n` +
          `consoleSamples=${JSON.stringify(consoleSamples)}`,
    );
  }

  const lines = REQUIRED.map((cp) => byCheckpoint.get(cp));

  await fs.mkdir(path.dirname(OUTPUT_PATH), { recursive: true });
  await fs.writeFile(OUTPUT_PATH, `${lines.join('\n')}\n`, 'utf8');

  await browser.close();

  console.log(`Captured startup timeline to ${OUTPUT_PATH}`);
}

main().catch((error) => {
  console.error(error && error.stack ? error.stack : error);
  process.exit(1);
});
