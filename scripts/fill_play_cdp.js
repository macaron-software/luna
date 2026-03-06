#!/usr/bin/env node
/**
 * LUNA Play Console Auto-Fill via Chrome DevTools Protocol
 *
 * Connects to your existing Chrome session (already logged into Google)
 * using the Chrome remote debugging protocol. No re-login needed.
 *
 * Step 1 — Start Chrome with debugging (run once):
 *   /Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome \
 *     --remote-debugging-port=9222 --no-first-run --no-default-browser-check \
 *     "https://play.google.com/console/u/0/developers/6295830866613067582/app/4973061748192418870/main-store-listing"
 *
 * Step 2 — In that Chrome window, make sure you're logged into Google Play Console
 *
 * Step 3 — Run this script:
 *   node scripts/fill_play_cdp.js
 *   node scripts/fill_play_cdp.js --locale en-US   (single locale)
 *   node scripts/fill_play_cdp.js --dry-run        (navigate only)
 *   node scripts/fill_play_cdp.js --text-only      (no screenshots)
 */

const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');
const http = require('http');

// ── Config ────────────────────────────────────────────────────────────────────
const CDP_PORT     = 18800;  // existing Chrome instance (Finary scrapers Chrome)
const DEVELOPER_ID = '6295830866613067582';
const APP_ID       = '4973061748192418870';
const METADATA_DIR = path.join(__dirname, '..', 'fastlane', 'metadata', 'android');

const LOCALE_MAP = {
  'ar-SA': 'ar', 'iw-IL': 'iw', 'no-NO': 'no-NO', 'nb-NO': 'no-NO',
  'zh-CN': 'zh-CN', 'zh-TW': 'zh-TW', 'pt-BR': 'pt-BR', 'pt-PT': 'pt-PT',
  'es-ES': 'es-ES', 'es-419': 'es-419', 'fr-FR': 'fr-FR', 'fr-CA': 'fr-CA',
  'de-DE': 'de-DE', 'it-IT': 'it-IT', 'ja-JP': 'ja-JP', 'ko-KR': 'ko-KR',
  'nl-NL': 'nl-NL', 'pl-PL': 'pl-PL', 'ru-RU': 'ru-RU', 'tr-TR': 'tr-TR',
  'sv-SE': 'sv-SE', 'da-DK': 'da-DK', 'fi-FI': 'fi-FI', 'cs-CZ': 'cs-CZ',
  'hu-HU': 'hu-HU', 'ro': 'ro', 'bg': 'bg', 'uk': 'uk', 'el-GR': 'el-GR',
  'hi-IN': 'hi-IN', 'id': 'id', 'ms-MY': 'ms-MY', 'th': 'th', 'vi': 'vi',
  'fa': 'fa', 'bn-BD': 'bn-BD', 'ta-IN': 'ta-IN', 'ur': 'ur',
  'sk': 'sk', 'hr': 'hr', 'en-US': 'en-US',
};
function gpLocale(folder) { return LOCALE_MAP[folder] || folder; }

// ── Args ──────────────────────────────────────────────────────────────────────
const args = process.argv.slice(2);
const DRY_RUN    = args.includes('--dry-run');
const TEXT_ONLY  = args.includes('--text-only');
const SINGLE_LOC = args.includes('--locale') ? args[args.indexOf('--locale') + 1] : null;

// ── CDP check ─────────────────────────────────────────────────────────────────
function checkCDP() {
  return new Promise((resolve) => {
    http.get(`http://localhost:${CDP_PORT}/json/version`, (res) => {
      let data = '';
      res.on('data', d => data += d);
      res.on('end', () => {
        try { resolve(JSON.parse(data)); } catch { resolve(null); }
      });
    }).on('error', () => resolve(null));
  });
}

// ── Main ──────────────────────────────────────────────────────────────────────
(async () => {
  console.log('┌─────────────────────────────────────────────────────────────┐');
  console.log('│  LUNA Play Console Auto-Fill  (CDP mode)                    │');
  console.log('└─────────────────────────────────────────────────────────────┘\n');

  // Check Chrome debugging is available
  const cdpInfo = await checkCDP();
  if (!cdpInfo) {
    console.error('❌  Chrome not found on port 9222.\n');
    console.error('Run this command first, then re-run this script:\n');
    console.error(`  /Applications/Google\\ Chrome.app/Contents/MacOS/Google\\ Chrome \\`);
    console.error(`    --remote-debugging-port=9222 --no-first-run \\`);
    console.error(`    "https://play.google.com/console/u/0/developers/${DEVELOPER_ID}/app/${APP_ID}/main-store-listing"\n`);
    process.exit(1);
  }

  console.log(`✓ Connected to Chrome ${cdpInfo.Browser}\n`);

  // Connect via CDP
  const browser = await chromium.connectOverCDP(`http://localhost:${CDP_PORT}`);
  const contexts = browser.contexts();
  const context  = contexts[0];
  const pages    = context.pages();

  // Use existing page or open new one
  let page = pages.find(p => p.url().includes('play.google.com')) || pages[0];
  if (!page) page = await context.newPage();

  // Verify we're logged in
  const currentUrl = page.url();
  if (!currentUrl.includes('play.google.com/console')) {
    await page.goto(
      `https://play.google.com/console/u/0/developers/${DEVELOPER_ID}/app/${APP_ID}/main-store-listing`,
      { waitUntil: 'load', timeout: 30000 }
    );
    await page.waitForTimeout(2000);
  }

  if (page.url().includes('accounts.google') || page.url().includes('signin')) {
    console.error('❌  Not logged in to Play Console.');
    console.error('   Log in to play.google.com/console in the Chrome window, then re-run.\n');
    await browser.close();
    process.exit(1);
  }

  console.log('✓ Logged into Play Console\n');

  // Load locales
  const locales = fs.readdirSync(METADATA_DIR)
    .filter(l => fs.statSync(path.join(METADATA_DIR, l)).isDirectory())
    .filter(l => !SINGLE_LOC || l === SINGLE_LOC)
    .sort();

  if (locales.length === 0) {
    console.error(`No locales found${SINGLE_LOC ? ` for ${SINGLE_LOC}` : ''}`);
    process.exit(1);
  }

  console.log(`Processing ${locales.length} locale(s)${DRY_RUN ? ' [DRY RUN]' : ''}...\n`);

  let ok = 0;
  const errors = [];

  for (const folder of locales) {
    const gp  = gpLocale(folder);
    const dir = path.join(METADATA_DIR, folder);

    const title = readFile(dir, 'title.txt');
    const short = readFile(dir, 'short_description.txt');
    const full  = readFile(dir, 'full_description.txt');

    if (!title) { console.log(`  [${folder}] SKIP — no title.txt`); continue; }

    console.log(`\n── ${folder} (${gp}) ${'─'.repeat(40 - folder.length - gp.length)}`);

    // Navigate to store listing for this locale
    const url = folder === 'en-US'
      ? `https://play.google.com/console/u/0/developers/${DEVELOPER_ID}/app/${APP_ID}/main-store-listing`
      : `https://play.google.com/console/u/0/developers/${DEVELOPER_ID}/app/${APP_ID}/store-listing-languages/translation/${gp}`;

    try {
      await page.goto(url, { waitUntil: 'networkidle', timeout: 30000 });
      await page.waitForTimeout(2000);

      if (DRY_RUN) {
        console.log(`  [DRY RUN] ${url}`);
        ok++;
        continue;
      }

      // Fill fields
      const titleOk = await fillField(page, title, 'App name');
      const shortOk = await fillField(page, short, 'Short description');
      const fullOk  = await fillField(page, full,  'Full description');

      // Save
      if (titleOk || shortOk || fullOk) {
        await clickSave(page);
      }

      console.log(`  ✓ Saved`);
      ok++;
      await page.waitForTimeout(1500);

    } catch (err) {
      console.error(`  ✗ ERROR: ${err.message}`);
      errors.push(`${folder}: ${err.message}`);
      await page.screenshot({ path: `/tmp/luna_play_error_${folder}.png` }).catch(() => {});
    }
  }

  console.log(`\n${'─'.repeat(60)}`);
  console.log(`✅ Done: ${ok}/${locales.length} locales filled`);
  if (errors.length) {
    console.log(`\n❌ Errors (${errors.length}):`);
    errors.forEach(e => console.log(`  ${e}`));
  }

  await browser.close();
})();

// ── Helpers ───────────────────────────────────────────────────────────────────

function readFile(dir, filename) {
  const p = path.join(dir, filename);
  return fs.existsSync(p) ? fs.readFileSync(p, 'utf8').trim() : '';
}

async function fillField(page, value, label) {
  if (!value) return false;

  // Multilingual label aliases (Play Console UI language varies)
  // NOTE: The aria-label is on the [role="group"] container, not the input itself.
  // Actual DOM: [role="group"][aria-label="Nom de l'application"] > input
  const labelAliases = {
    'App name': ["Nom de l'application", "App name", "Application name", "Nombre de la app", "Anwendungsname", "Nome dell'app"],
    'Short description': ["Brève description", "Brève description de l'application", "Short description", "Breve descrizione", "Kurze Beschreibung", "Breve descripción"],
    'Full description': ["Description complète", "Description complète de l'application", "Full description", "Beschreibung", "Descrizione completa"],
  };
  const aliases = labelAliases[label] || [label];

  // Strategy 1: group container with aria-label → nested input/textarea
  for (const al of aliases) {
    for (const inputTag of ['input', 'textarea']) {
      try {
        const sel = `[role="group"][aria-label="${al}"] ${inputTag}`;
        const el = page.locator(sel).first();
        if (await el.count() > 0) {
          await el.click({ clickCount: 3 });
          await el.fill(value);
          console.log(`  ✓ ${label} (group>${inputTag} "${al.substring(0,25)}"): ${value.length} chars`);
          return true;
        }
      } catch {}
      try {
        const sel = `[role="group"][aria-label*="${al}"] ${inputTag}`;
        const el = page.locator(sel).first();
        if (await el.count() > 0) {
          await el.click({ clickCount: 3 });
          await el.fill(value);
          console.log(`  ✓ ${label} (group*>${inputTag} "${al.substring(0,25)}"): ${value.length} chars`);
          return true;
        }
      } catch {}
    }
  }

  // Strategy 2: direct aria-label on input/textarea
  const ariaSelectors = aliases.flatMap(al => [
    `input[aria-label="${al}"]`, `textarea[aria-label="${al}"]`,
    `input[aria-label*="${al}"]`, `textarea[aria-label*="${al}"]`,
  ]);
  for (const sel of ariaSelectors) {
    try {
      const el = page.locator(sel).first();
      if (await el.count() > 0) {
        await el.click({ clickCount: 3 });
        await el.fill(value);
        console.log(`  ✓ ${label} (${sel.split('"')[1].substring(0,25)}): ${value.length} chars`);
        return true;
      }
    } catch {}
  }

  // Strategy 3: mat-form-field with any alias label
  for (const al of aliases) {
    try {
      const f = page.locator(`mat-form-field:has(*[aria-label*="${al}"])`).first();
      if (await f.count() > 0) {
        const inp = f.locator('textarea, input').first();
        if (await inp.count() > 0) {
          await inp.click({ clickCount: 3 });
          await inp.fill(value);
          console.log(`  ✓ ${label} (mat-form-field): ${value.length} chars`);
          return true;
        }
      }
    } catch {}
  }

  // Strategy 3: formcontrolname
  const controlNames = { 'App name': 'title', 'Short description': 'shortDescription', 'Full description': 'fullDescription' };
  const controlName = controlNames[label];
  if (controlName) {
    for (const t of ['textarea', 'input']) {
      try {
        const el = page.locator(`${t}[formcontrolname="${controlName}"]`).first();
        if (await el.count() > 0) { await el.click({clickCount:3}); await el.fill(value); console.log(`  ✓ ${label} (formcontrol): ${value.length} chars`); return true; }
      } catch {}
    }
  }

  // Strategy 4: positional fallback based on DOM order
  // Order: App name (input[0]), Short description (input[1]), Full description (textarea[0])
  const posMap = {
    'App name':         { tag: 'input',    idx: 0 },
    'Short description':{ tag: 'input',    idx: 1 },
    'Full description': { tag: 'textarea', idx: 0 },
  };
  const pos = posMap[label];
  if (pos) {
    try {
      const els = page.locator(pos.tag);
      if (await els.count() > pos.idx) {
        const el = els.nth(pos.idx);
        await el.click({ clickCount: 3 });
        await el.fill(value);
        console.log(`  ✓ ${label} (positional ${pos.tag}[${pos.idx}]): ${value.length} chars`);
        return true;
      }
    } catch {}
  }

  console.warn(`  ⚠️  Could not fill "${label}"`);
  return false;
}

async function clickSave(page) {
  const selectors = [
    'button:has-text("Save")', 'button:has-text("Enregistrer")',
    'button:has-text("Sauvegarder")', '[aria-label="Save"]',
    'button[type="submit"]',
  ];
  for (const sel of selectors) {
    try {
      const btn = await page.$(sel);
      if (btn) { await btn.click(); await page.waitForTimeout(2000); return; }
    } catch {}
  }
  console.warn('  ⚠️  Save button not found');
}
