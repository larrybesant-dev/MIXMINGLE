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

  page.on('console', (msg) => {
    const line = extractStartupLine(msg.text());
    if (!line) return;
    const checkpoint = checkpointFromLine(line);
    if (!checkpoint) return;
    if (!byCheckpoint.has(checkpoint)) {
      byCheckpoint.set(checkpoint, line);
    }
  });

  await page.goto(APP_URL, { waitUntil: 'domcontentloaded', timeout: CAPTURE_TIMEOUT_MS });

  const startedAt = Date.now();
  while (Date.now() - startedAt < CAPTURE_TIMEOUT_MS) {
    const hasAll = REQUIRED.every((cp) => byCheckpoint.has(cp));
    if (hasAll) break;
    await page.waitForTimeout(250);
  }

  await browser.close();

  const missing = REQUIRED.filter((cp) => !byCheckpoint.has(cp));
  if (missing.length > 0) {
    throw new Error(`Missing startup checkpoints from real runtime console: ${missing.join(', ')}`);
  }

  const lines = REQUIRED.map((cp) => byCheckpoint.get(cp));

  await fs.mkdir(path.dirname(OUTPUT_PATH), { recursive: true });
  await fs.writeFile(OUTPUT_PATH, `${lines.join('\n')}\n`, 'utf8');

  console.log(`Captured startup timeline to ${OUTPUT_PATH}`);
}

main().catch((error) => {
  console.error(error && error.stack ? error.stack : error);
  process.exit(1);
});
