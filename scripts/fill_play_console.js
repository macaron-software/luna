#!/usr/bin/env node
/**
 * LUNA Play Console Auto-Fill
 *
 * Uses a copy of your Chrome profile (logged into Google) to fill
 * all 40 Play Store listings automatically. Chrome can stay open.
 *
 * Usage:
 *   node scripts/fill_play_console.js
 *   node scripts/fill_play_console.js --locale en-US   (single locale test)
 *   node scripts/fill_play_console.js --dry-run        (navigate only, no fill)
 */

const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');
const os = require('os');
const { execSync } = require('child_process');

// ── Config ────────────────────────────────────────────────────────────────────
const DEVELOPER_ID = '6295830866613067582';
const APP_ID       = '4973061748192418870';
const METADATA_DIR = path.join(__dirname, '..', 'fastlane', 'metadata', 'android');

// Map our folder names → Play Console locale codes
const LOCALE_MAP = {
  'ar-SA':  'ar',
  'iw-IL':  'iw',
  'nb-NO':  'no-NO',
  'no-NO':  'no-NO',
};
function gpLocale(folder) { return LOCALE_MAP[folder] || folder; }

// Parse args
const args = process.argv.slice(2);
const DRY_RUN      = args.includes('--dry-run');
const SINGLE_LOC   = args.includes('--locale') ? args[args.indexOf('--locale') + 1] : null;
const HEADLESS     = args.includes('--headless');

// ── Main ─────────────────────────────────────────────────────────────────────
(async () => {
  // Use a fresh temp profile — user will log in once, then we fill everything
  const tmpProfile = path.join(os.tmpdir(), 'luna-play-console-session');
  if (!fs.existsSync(tmpProfile)) fs.mkdirSync(tmpProfile, { recursive: true });

  console.log('┌─────────────────────────────────────────────┐');
  console.log('│  LUNA Play Console Auto-Fill                │');
  console.log('│  A browser window will open.                │');
  console.log('│  Log in to Google once → script fills all   │');
  console.log('│  40 store listings automatically.           │');
  console.log('└─────────────────────────────────────────────┘\n');
  if (DRY_RUN) console.log('DRY RUN — navigating only, no form fill\n');

  const context = await chromium.launchPersistentContext(tmpProfile, {
    headless: false,  // must be headed so user can log in
    args: ['--no-sandbox'],
    viewport: { width: 1400, height: 900 },
    slowMo: 50,
  });

  const page = await context.newPage();

  // Navigate to Play Console — user logs in if needed
  console.log('Opening Play Console...');
  await page.goto(
    `https://play.google.com/console/u/0/developers/${DEVELOPER_ID}/app/${APP_ID}/main-store-listing`,
    { waitUntil: 'load', timeout: 15000 }
  ).catch(() => {});

  // Wait for login if redirected to Google auth
  const currentUrl = page.url();
  if (currentUrl.includes('accounts.google') || currentUrl.includes('signin')) {
    console.log('\n⏳ Please log in to Google Play Console in the browser window...');
    console.log('   Waiting up to 3 minutes for login...\n');
    
    // Wait until we're back on Play Console
    await page.waitForURL(
      '**/play.google.com/console/**',
      { timeout: 180000 }  // 3 minute timeout for login
    );
    console.log('✓ Logged in!\n');
    await page.waitForTimeout(2000);
  }

  // Load metadata
  const locales = fs.readdirSync(METADATA_DIR)
    .filter(l => fs.statSync(path.join(METADATA_DIR, l)).isDirectory())
    .filter(l => !SINGLE_LOC || l === SINGLE_LOC)
    .sort();

  if (locales.length === 0) {
    console.error(`No locales found${SINGLE_LOC ? ` for ${SINGLE_LOC}` : ''}`);
    process.exit(1);
  }

  console.log(`Processing ${locales.length} locale(s)...\n`);

  let ok = 0, errors = [];

  for (const folder of locales) {
    const gp = gpLocale(folder);
    const dir = path.join(METADATA_DIR, folder);

    const title = readFile(dir, 'title.txt');
    const short = readFile(dir, 'short_description.txt');
    const full  = readFile(dir, 'full_description.txt');

    if (!title) { console.log(`  [${folder}] SKIP — no title.txt`); continue; }

    console.log(`\n── ${folder} (${gp}) ──────────────────────────────`);
    console.log(`  Title: ${title}`);

    // Navigate to store listing for this locale
    let url;
    if (folder === 'en-US') {
      url = `https://play.google.com/console/u/0/developers/${DEVELOPER_ID}/app/${APP_ID}/main-store-listing`;
    } else {
      url = `https://play.google.com/console/u/0/developers/${DEVELOPER_ID}/app/${APP_ID}/store-listing-languages/translation/${gp}`;
    }

    try {
      console.log(`  → ${url}`);
      await page.goto(url, { waitUntil: 'networkidle', timeout: 30000 });
      await page.waitForTimeout(2000);

      if (DRY_RUN) {
        console.log(`  [DRY RUN] Would fill: title, short desc, full desc`);
        ok++;
        continue;
      }

      // Fill App name / Title
      await fillField(page, title, 'app-name', 'App name');

      // Fill Short description
      await fillField(page, short, 'short-description', 'Short description');

      // Fill Full description
      await fillField(page, full, 'full-description', 'Full description');

      // Save
      await clickSave(page);

      console.log(`  ✓ Saved`);
      ok++;

      // Wait between locales to avoid rate limiting
      await page.waitForTimeout(1500);

    } catch (err) {
      console.error(`  ✗ ERROR: ${err.message}`);
      errors.push(`${folder}: ${err.message}`);
      // Take screenshot for debugging
      await page.screenshot({ path: `/tmp/luna_play_error_${folder}.png` });
      console.error(`  Screenshot: /tmp/luna_play_error_${folder}.png`);
    }
  }

  console.log(`\n${'─'.repeat(60)}`);
  console.log(`✅ Done: ${ok}/${locales.length} locales filled`);
  if (errors.length) {
    console.log(`\n❌ Errors (${errors.length}):`);
    errors.forEach(e => console.log(`  ${e}`));
  }

  await context.close();
})();

// ── Helpers ───────────────────────────────────────────────────────────────────

function readFile(dir, filename) {
  const p = path.join(dir, filename);
  return fs.existsSync(p) ? fs.readFileSync(p, 'utf8').trim() : '';
}

/**
 * Fill a text field in Play Console (Angular Material Design).
 * Play Console uses Angular components with dynamic attributes.
 * We try multiple strategies in order.
 */
async function fillField(page, value, fieldType, label) {
  // Strategy 1: aria-label variants
  const ariaLabels = [label, label.toLowerCase()];
  for (const al of ariaLabels) {
    for (const tag of ['textarea', 'input']) {
      try {
        const el = page.locator(`${tag}[aria-label="${al}"]`).first();
        if (await el.count() > 0) {
          await el.click({ clickCount: 3 });
          await el.fill(value);
          console.log(`  ✓ ${label}: ${value.length} chars`);
          return true;
        }
      } catch {}
    }
  }

  // Strategy 2: placeholder text
  for (const tag of ['textarea', 'input']) {
    try {
      const el = page.locator(`${tag}[placeholder*="${label}"]`).first();
      if (await el.count() > 0) {
        await el.click({ clickCount: 3 });
        await el.fill(value);
        console.log(`  ✓ ${label} (placeholder): ${value.length} chars`);
        return true;
      }
    } catch {}
  }

  // Strategy 3: label text → sibling/child textarea
  try {
    const el = page.locator(`label:has-text("${label}") ~ * textarea, label:has-text("${label}") textarea`).first();
    if (await el.count() > 0) {
      await el.click({ clickCount: 3 });
      await el.fill(value);
      console.log(`  ✓ ${label} (label sibling): ${value.length} chars`);
      return true;
    }
  } catch {}

  // Strategy 4: content-editable (Play Console uses these for rich text)
  try {
    const el = page.locator(`[contenteditable="true"]`).first();
    if (await el.count() > 0) {
      await el.click({ clickCount: 3 });
      await page.keyboard.press('Control+a');
      await el.type(value, { delay: 10 });
      console.log(`  ✓ ${label} (contenteditable): ${value.length} chars`);
      return true;
    }
  } catch {}

  console.warn(`  ⚠️  Could not auto-fill "${label}" — fill manually`);
  return false;
}

async function clickSave(page) {
  const saveSelectors = [
    'button:has-text("Save")',
    'button:has-text("Enregistrer")',
    'button:has-text("Sauvegarder")',
    '[aria-label="Save"]',
    '[data-action="save"]',
    'button[type="submit"]',
  ];

  for (const sel of saveSelectors) {
    try {
      const btn = await page.$(sel);
      if (btn) {
        await btn.click();
        await page.waitForTimeout(2000);
        return;
      }
    } catch {}
  }
  console.warn('  ⚠️  Save button not found');
}
