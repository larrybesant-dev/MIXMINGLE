const fs = require('fs/promises');
const path = require('path');
const { chromium } = require('playwright');

const APP_URL = process.env.STARTUP_APP_URL || 'http://127.0.0.1:8080/';
const OUTPUT_PATH = process.env.STARTUP_LOG_PATH || 'tools/reports/startup_timeline.log';
const CAPTURE_TIMEOUT_MS = Number(process.env.STARTUP_CAPTURE_TIMEOUT_MS || '45000');

const REQUIRED = [
  'mainStart',
  'bindingReady',
  'firebaseReady',
  'bootstrapResolved',
  'firstFrameRendered',
];

const WINDOW_TIMELINE_KEY = '__mixvyStartupTimeline';

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

  await page.goto(APP_URL, { waitUntil: 'domcontentloaded', timeout: CAPTURE_TIMEOUT_MS });

  const startedAt = Date.now();
  while (Date.now() - startedAt < CAPTURE_TIMEOUT_MS) {
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
        sessionTimeline: window.sessionStorage.getItem('__mixvyStartupTimeline') || '',
      }))
      .catch(() => null);

    throw new Error(
      `Missing startup checkpoints from real runtime console: ${missing.join(', ')}\n` +
          `bootState=${JSON.stringify(bootState)}\n` +
          `pageErrors=${JSON.stringify(pageErrors)}\n` +
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
