#!/usr/bin/env node
/**
 * upload_play_assets.js
 *
 * Uploads graphical assets to Play Store via CDP (Chrome on port 18800).
 *
 * ROOT CAUSE: Chrome CDP file chooser interception only works once per page session
 * (page.goto). The 2nd upload in the same session ALWAYS fails regardless of order.
 * FIX: One upload per page.goto(). Two passes: screenshots first, then FG.
 *
 * Usage:
 *   node scripts/upload_play_assets.js              # run all remaining
 *   node scripts/upload_play_assets.js --locale fr-FR   # single locale
 *   node scripts/upload_play_assets.js --screenshots-only
 *   node scripts/upload_play_assets.js --fg-only
 *   node scripts/upload_play_assets.js --reset-progress  # clear progress cache
 */

const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

const CDP_PORT     = 18800;
const DEVELOPER_ID = '6295830866613067582';
const APP_ID       = '4973061748192418870';
const LISTING_URL  = `https://play.google.com/console/u/0/developers/${DEVELOPER_ID}/app/${APP_ID}/main-store-listing`;
const METADATA_DIR = path.join(__dirname, '..', 'fastlane', 'metadata', 'android');
const PROGRESS_FILE = path.join(__dirname, 'upload_progress.json');

// Map GP code → metadata folder name
const GP_TO_FOLDER = {
  'ar': 'ar-SA', 'bg': 'bg', 'bn-BD': 'bn-BD', 'cs-CZ': 'cs-CZ', 'da-DK': 'da-DK',
  'de-DE': 'de-DE', 'el-GR': 'el-GR', 'es-419': 'es-419', 'es-ES': 'es-ES', 'fa': 'fa',
  'fi-FI': 'fi-FI', 'fr-CA': 'fr-CA', 'fr-FR': 'fr-FR', 'hi-IN': 'hi-IN', 'hr': 'hr',
  'hu-HU': 'hu-HU', 'id': 'id', 'it-IT': 'it-IT', 'iw-IL': 'iw-IL', 'ja-JP': 'ja-JP',
  'ko-KR': 'ko-KR', 'ms-MY': 'ms-MY', 'nl-NL': 'nl-NL', 'no-NO': 'no-NO', 'pl-PL': 'pl-PL',
  'pt-BR': 'pt-BR', 'pt-PT': 'pt-PT', 'ro': 'ro', 'ru-RU': 'ru-RU', 'sk': 'sk',
  'sv-SE': 'sv-SE', 'ta-IN': 'ta-IN', 'th': 'th', 'tr-TR': 'tr-TR', 'uk': 'uk',
  'ur': 'ur', 'vi': 'vi', 'zh-CN': 'zh-CN', 'zh-TW': 'zh-TW',
};
const TARGET_GP_CODES = Object.keys(GP_TO_FOLDER);

// Button indices (all 7 asset slots, stable using [add-button,add-more-button] nth()):
const BTN_ICON        = 0;  // 512x512 icon
const BTN_FG          = 1;  // 1024x500 feature graphic
const BTN_SCREENSHOTS = 2;  // phone screenshots

const args          = process.argv.slice(2);
const SINGLE        = args.includes('--locale')     ? args[args.indexOf('--locale') + 1]     : null;
const SCREENSHOTS_ONLY = args.includes('--screenshots-only');
const FG_ONLY       = args.includes('--fg-only');
const RESET_PROGRESS = args.includes('--reset-progress');

// ---------- Progress tracking ----------
function loadProgress() {
  if (RESET_PROGRESS && fs.existsSync(PROGRESS_FILE)) {
    fs.unlinkSync(PROGRESS_FILE);
    console.log('Progress reset.\n');
  }
  if (fs.existsSync(PROGRESS_FILE)) {
    return JSON.parse(fs.readFileSync(PROGRESS_FILE, 'utf8'));
  }
  // Pre-seed known-done locales from previous sessions
  return {
    'en-US':  { screenshots: true, fg: true, icon: true },
    'it-IT':  { screenshots: true, fg: true },
    'nl-NL':  { screenshots: true },
    'pt-BR':  { screenshots: true },
    'sv-SE':  { screenshots: true },
    'no-NO':  { screenshots: true },
    'fr-FR':  { fg: true },
    'de-DE':  { fg: true },
    'ar-SA':  { fg: true },
  };
}
function saveProgress(progress) {
  fs.writeFileSync(PROGRESS_FILE, JSON.stringify(progress, null, 2));
}
function markDone(progress, folder, type) {
  if (!progress[folder]) progress[folder] = {};
  progress[folder][type] = true;
  saveProgress(progress);
}
function isDone(progress, folder, type) {
  return !!progress[folder]?.[type];
}

// ---------- Asset helpers ----------
function getAssets(folder) {
  const base = path.join(METADATA_DIR, folder, 'images');
  const icon = path.join(METADATA_DIR, 'en-US', 'images', 'icon.png');
  const fg   = path.join(base, 'featureGraphic.png');
  const shots = fs.existsSync(path.join(base, 'phoneScreenshots'))
    ? fs.readdirSync(path.join(base, 'phoneScreenshots'))
        .filter(f => /\.(png|jpg|jpeg)$/i.test(f)).sort()
        .map(f => path.join(base, 'phoneScreenshots', f))
    : [];
  return {
    icon: fs.existsSync(icon) ? icon : null,
    featureGraphic: fs.existsSync(fg) ? fg : null,
    phoneScreenshots: shots,
  };
}

// ---------- Page helpers ----------
async function gotoListing(page) {
  for (let i = 0; i < 3; i++) {
    try {
      await page.goto(LISTING_URL, { waitUntil: 'load', timeout: 40000 });
      await page.waitForTimeout(3000);
      return true;
    } catch (e) {
      console.log(`  ⚠ goto failed (${i+1}/3): ${e.message.split('\n')[0]}`);
      await page.waitForTimeout(3000);
    }
  }
  return false;
}

async function addSingleLanguage(page, gpCode) {
  await page.locator('button[aria-haspopup="listbox"]').first().click({ timeout: 5000 });
  await page.waitForTimeout(800);
  await page.evaluate(() => {
    Array.from(document.querySelectorAll('[role="option"], button, li, .item'))
      .find(el => el.textContent.trim() === 'Sélectionner les langues')?.click();
  });
  await page.waitForTimeout(2000);
  const item = page.locator('[role="dialog"] .item').filter({ hasText: `– ${gpCode}` }).first();
  if (await item.count() > 0) {
    const cb = item.locator('material-checkbox').first();
    if ((await cb.getAttribute('aria-checked')) !== 'true') await cb.click();
    await page.waitForTimeout(100);
  }
  await page.locator('[role="dialog"] button:has-text("Appliquer")').first().click({ timeout: 3000 });
  await page.waitForTimeout(3000);
}

async function switchToLanguage(page, gpCode) {
  const btn = page.locator('language-control dropdown-button').first();
  if (await btn.count() === 0) return false;
  await btn.click();
  await page.waitForTimeout(1000);
  const opt = page.locator(`[role="option"]:has-text("– ${gpCode}")`).first();
  if (await opt.count() === 0) return false;
  await opt.click();
  await page.waitForTimeout(2000);
  return true;
}

async function closePanelIfOpen(page) {
  const closed = await page.evaluate(() => {
    const btn = document.querySelector('[debug-id="close-button"]');
    if (btn) { btn.click(); return true; }
    return false;
  });
  if (closed) await page.waitForTimeout(600);
}

// ---------- Core upload function ----------
// Upload a single asset type with ONE file chooser per call.
// btnIndex: 0=icon, 1=FG, 2=screenshots (stable nth() of [add-button,add-more-button])
async function uploadSection(page, btnIndex, files, label) {
  if (!files || (Array.isArray(files) && files.length === 0)) return 'no-files';
  const fileArr = Array.isArray(files) ? files : [files];

  const allBtns = page.locator('[debug-id="add-button"], [debug-id="add-more-button"]');
  const sectionBtn = allBtns.nth(btnIndex);
  if (await sectionBtn.count() === 0) {
    console.log(`    ✗ ${label}: section button not found`);
    return 'error';
  }
  if (await sectionBtn.isDisabled()) {
    console.log(`    ⏭ ${label}: slot full, skipping`);
    return 'skip';
  }

  // 1. Open asset library panel
  await sectionBtn.click({ force: true });
  await page.waitForTimeout(800);

  const uploadBtn = page.locator('[debug-id="upload-button"]').first();
  await uploadBtn.waitFor({ timeout: 5000 }).catch(() => {});
  if (await uploadBtn.count() === 0) {
    console.log(`    ✗ ${label}: upload-button not found in panel`);
    return 'error';
  }

  // 2. File chooser (works reliably as the FIRST chooser after page.goto())
  let chooser;
  try {
    [chooser] = await Promise.all([
      page.waitForEvent('filechooser', { timeout: 10000 }),
      uploadBtn.click(),
    ]);
  } catch (e) {
    console.log(`    ✗ ${label}: file chooser timed out — ${e.message.split('\n')[0]}`);
    await closePanelIfOpen(page);
    return 'error';
  }

  // 3. Set files
  await chooser.setFiles(fileArr);

  // 4. Wait for upload
  await page.waitForTimeout(4000 + fileArr.length * 800);

  // 5. Click "Ajouter" to add assets to listing form
  const addToContent = page.locator('[debug-id="add-to-content-button"]').first();
  if (await addToContent.count() === 0) {
    console.log(`    ✗ ${label}: add-to-content-button not found — may already be uploaded`);
    await closePanelIfOpen(page);
    return 'already-done';  // Slot may already have max assets
  }
  await addToContent.click();
  await page.waitForTimeout(500);
  await closePanelIfOpen(page);

  const sizes = fileArr.map(f => `${(fs.statSync(f).size / 1024).toFixed(0)}KB`);
  console.log(`    ✓ ${label}: ${fileArr.length} file(s) [${sizes.join(', ')}]`);
  return 'ok';
}

async function clickSave(page) {
  for (const name of ['Enregistrer', 'Save']) {
    const btn = page.getByRole('button', { name, exact: true }).first();
    if (await btn.count() > 0 && await btn.isEnabled()) {
      await btn.click();
      await page.waitForTimeout(3000);
      return true;
    }
  }
  const clicked = await page.evaluate(() => {
    const b = Array.from(document.querySelectorAll('button')).find(b => b.textContent.trim() === 'Enregistrer' && !b.disabled);
    if (b) { b.click(); return true; }
    return false;
  });
  if (clicked) { await page.waitForTimeout(3000); return true; }
  return false;
}

// ---------- Upload one asset type for one locale (fresh page.goto() each time) ----------
async function uploadLocaleSingleAsset(page, gpCode, folder, isDefault, btnIndex, files, label) {
  if (!files || (Array.isArray(files) && files.length === 0)) return 'no-files';

  const loaded = await gotoListing(page);
  if (!loaded) return 'error';

  if (!isDefault) {
    try {
      await addSingleLanguage(page, gpCode);
      const switched = await switchToLanguage(page, gpCode);
      if (!switched) { console.log(`  ✗ Could not switch to ${gpCode}`); return 'error'; }
    } catch (e) {
      console.log(`  ✗ Language setup: ${e.message.split('\n')[0]}`);
      return 'error';
    }
  }
  await page.waitForTimeout(500);

  const result = await uploadSection(page, btnIndex, files, label);
  if (result === 'ok') {
    const saved = await clickSave(page);
    if (!saved) { console.log('  ✗ Save failed'); return 'error'; }
    console.log('  ✓ Saved');
    return 'ok';
  }
  if (result === 'skip' || result === 'already-done') return result;
  return 'error';
}

// ---------- MAIN ----------
(async () => {
  console.log('╔══════════════════════════════════════════════════════════╗');
  console.log('║  LUNA Play Store — Upload Graphical Assets (1-per-reload) ║');
  console.log('╚══════════════════════════════════════════════════════════╝\n');

  const progress = loadProgress();
  const browser = await chromium.connectOverCDP(`http://localhost:${CDP_PORT}`);
  const context = browser.contexts()[0];
  let page = context.pages().find(p => p.url().includes('play.google.com'))
           || context.pages().find(p => p.url().includes('chrome-error'))
           || context.pages()[0];

  // Build locale list
  let locales = [];
  if (SINGLE) {
    if (SINGLE === 'en-US') {
      locales = [{ gpCode: null, folder: 'en-US', isDefault: true }];
    } else {
      const gpCode = Object.entries(GP_TO_FOLDER).find(([k, v]) => v === SINGLE || k === SINGLE)?.[0];
      if (!gpCode) { console.error(`Unknown locale: ${SINGLE}`); process.exit(1); }
      locales = [{ gpCode, folder: GP_TO_FOLDER[gpCode], isDefault: false }];
    }
  } else {
    locales = [
      { gpCode: null, folder: 'en-US', isDefault: true },
      ...TARGET_GP_CODES.map(gpCode => ({ gpCode, folder: GP_TO_FOLDER[gpCode], isDefault: false })),
    ];
  }

  let done = 0, skipped = 0, failed = [];

  // ═══ PASS 1: Screenshots ═══
  if (!FG_ONLY) {
    console.log('═══ PASS 1: Phone Screenshots ═══\n');
    for (const { gpCode, folder, isDefault } of locales) {
      const assets = getAssets(folder);
      if (!assets.phoneScreenshots.length) continue;

      if (isDone(progress, folder, 'screenshots')) {
        console.log(`  ⏭ ${folder}: screenshots already done`);
        skipped++; continue;
      }

      console.log(`\n  [screenshots] ${folder}`);
      const result = await uploadLocaleSingleAsset(
        page, gpCode, folder, isDefault,
        BTN_SCREENSHOTS, assets.phoneScreenshots, `${assets.phoneScreenshots.length} screenshots`
      );
      if (result === 'ok') { markDone(progress, folder, 'screenshots'); done++; }
      else if (result === 'already-done') { markDone(progress, folder, 'screenshots'); skipped++; }
      else if (result === 'skip') skipped++;
      else failed.push(`${folder}:screenshots`);
    }
  }

  // ═══ PASS 2: Feature Graphics ═══
  if (!SCREENSHOTS_ONLY) {
    console.log('\n═══ PASS 2: Feature Graphics ═══\n');
    for (const { gpCode, folder, isDefault } of locales) {
      const assets = getAssets(folder);
      if (!assets.featureGraphic) continue;

      if (isDone(progress, folder, 'fg')) {
        console.log(`  ⏭ ${folder}: FG already done`);
        skipped++; continue;
      }

      console.log(`\n  [FG] ${folder}`);
      const result = await uploadLocaleSingleAsset(
        page, gpCode, folder, isDefault,
        BTN_FG, assets.featureGraphic, 'featureGraphic'
      );
      if (result === 'ok') { markDone(progress, folder, 'fg'); done++; }
      else if (result === 'already-done') { markDone(progress, folder, 'fg'); skipped++; }
      else if (result === 'skip') { markDone(progress, folder, 'fg'); skipped++; }
      else failed.push(`${folder}:fg`);
    }
  }

  // ═══ PASS 3: Icon (en-US only) ═══
  if (!SCREENSHOTS_ONLY && !FG_ONLY) {
    const enUS = locales.find(l => l.folder === 'en-US');
    if (enUS && !isDone(progress, 'en-US', 'icon')) {
      console.log('\n═══ PASS 3: Icon (en-US) ═══\n');
      const assets = getAssets('en-US');
      if (assets.icon) {
        console.log('  [icon] en-US');
        const result = await uploadLocaleSingleAsset(page, null, 'en-US', true, BTN_ICON, assets.icon, 'icon');
        if (result === 'ok' || result === 'skip') { markDone(progress, 'en-US', 'icon'); done++; }
        else if (result !== 'no-files') failed.push('en-US:icon');
      }
    }
  }

  console.log(`\n╔═══════════════════════════════════════════════╗`);
  console.log(`║  Uploaded: ${done} · Skipped: ${skipped} · Failed: ${failed.length}`);
  if (failed.length) console.log(`║  Failed: ${failed.join(', ')}`);
  console.log(`╚═══════════════════════════════════════════════╝`);

  const remaining = locales.filter(l => {
    const assets = getAssets(l.folder);
    const needShots = assets.phoneScreenshots.length > 0 && !isDone(progress, l.folder, 'screenshots');
    const needFG = !!assets.featureGraphic && !isDone(progress, l.folder, 'fg');
    return needShots || needFG;
  }).map(l => l.folder);
  if (remaining.length) console.log(`\nRemaining locales: ${remaining.join(', ')}`);
  else console.log('\n✅ All assets uploaded!');

  await browser.close();
})();
