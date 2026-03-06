#!/usr/bin/env node
/**
 * fill_play_all_locales.js
 * 
 * Single-session script to fill all 39 Play Store translation listings.
 * 
 * Strategy:
 * 1. Navigate to /main-store-listing
 * 2. Open language selection dialog → select all 39 langs → Apply (client-side)
 * 3. For each language: switch via dropdown → fill 3 fields → Save (server-persisted)
 * 
 * Usage: node scripts/fill_play_all_locales.js
 *        node scripts/fill_play_all_locales.js --start-from fr-FR
 */

const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

const CDP_PORT     = 18800;
const DEVELOPER_ID = '6295830866613067582';
const APP_ID       = '4973061748192418870';
const METADATA_DIR = path.join(__dirname, '..', 'fastlane', 'metadata', 'android');

// Map: Google Play dialog display code → our metadata folder name
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

const args = process.argv.slice(2);
const START_FROM = args.includes('--start-from') ? args[args.indexOf('--start-from') + 1] : null;
const SINGLE = args.includes('--locale') ? args[args.indexOf('--locale') + 1] : null;

function readMeta(folder, file) {
  const p = path.join(METADATA_DIR, folder, file);
  return fs.existsSync(p) ? fs.readFileSync(p, 'utf8').trim() : '';
}

async function waitForAngular(page) {
  await page.waitForTimeout(1200);
}

async function fillField(page, value, fieldHint) {
  // Strategy: find [role="group"] containing an aria-label matching the field
  const hints = {
    'name': ["Nom de l'application", "App name"],
    'short': ["Brève description", "Short description"],
    'full': ["Description complète", "Full description"],
  };
  const labels = hints[fieldHint] || [fieldHint];
  
  for (const label of labels) {
    for (const tag of ['input', 'textarea']) {
      const sel = `[role="group"][aria-label="${label}"] ${tag}`;
      const el = page.locator(sel).first();
      if (await el.count() > 0) {
        await el.scrollIntoViewIfNeeded();
        await el.click({ clickCount: 3 });
        await page.keyboard.press('Control+a');
        await el.fill(value);
        const len = value.length;
        console.log(`    ✓ ${fieldHint} (${len} chars)`);
        return true;
      }
    }
  }
  
  // Positional fallback
  if (fieldHint === 'name') {
    const inp = page.locator('input').first();
    if (await inp.count()) { await inp.click({clickCount:3}); await inp.fill(value); return true; }
  } else if (fieldHint === 'short') {
    const inps = page.locator('input');
    if (await inps.count() > 1) { await inps.nth(1).click({clickCount:3}); await inps.nth(1).fill(value); return true; }
  } else if (fieldHint === 'full') {
    const ta = page.locator('textarea').first();
    if (await ta.count()) { await ta.click({clickCount:3}); await ta.fill(value); return true; }
  }
  
  console.log(`    ✗ ${fieldHint}: field not found`);
  return false;
}

async function clickSave(page) {
  const saveSelectors = [
    'button:has-text("Enregistrer comme brouillon")',
    'button:has-text("Enregistrer")',
    'button:has-text("Save")',
  ];
  for (const sel of saveSelectors) {
    const btn = page.locator(sel).first();
    if (await btn.count() > 0 && await btn.isEnabled()) {
      await btn.click();
      await page.waitForTimeout(3000);
      const toast = await page.locator('[role="alert"], .snackbar, .notification, .toast').count();
      console.log(`    ✓ Saved (${sel.includes('brouillon') ? 'draft' : 'direct'})`);
      return true;
    }
  }
  console.log('    ✗ Save button not found');
  return false;
}

async function addLanguages(page) {
  console.log('  Opening language management...');
  const mgmtBtn = page.locator('button[aria-haspopup="listbox"]').first();
  if (await mgmtBtn.count() === 0) {
    // Try alternate selectors
    const altBtn = page.locator('button:has-text("Gérer"), button:has-text("Manage")').first();
    if (await altBtn.count() === 0) {
      console.log('  ✗ Management button not found');
      return false;
    }
    await altBtn.click();
  } else {
    await mgmtBtn.click();
  }
  await page.waitForTimeout(1500);
  
  // Click "Sélectionner les langues"
  await page.waitForTimeout(500);
  const selectLangsOption = page.locator(':text("Sélectionner les langues"), :text("Select languages")').first();
  if (await selectLangsOption.count() === 0) {
    // Try via evaluate
    const found = await page.evaluate(() => {
      const els = Array.from(document.querySelectorAll('[role="option"], button, li, .item'));
      for (const el of els) {
        if (el.textContent.trim() === 'Sélectionner les langues' || el.textContent.trim() === 'Select languages') {
          el.click();
          return true;
        }
      }
      return false;
    });
    if (!found) {
      console.log('  ✗ "Sélectionner les langues" option not found');
      return false;
    }
    await page.waitForTimeout(3000);
  } else {
    await selectLangsOption.click();
  }
  await page.waitForTimeout(3000);
  
  // Check dialog is open
  const dialog = page.locator('[role="dialog"]');
  if (await dialog.count() === 0) {
    console.log('  ✗ Dialog did not open');
    return false;
  }
  console.log('  Dialog open, selecting 39 languages...');
  
  let selected = 0;
  for (const code of TARGET_GP_CODES) {
    // Find the item with this code
    const item = dialog.locator(`.item`).filter({ hasText: `– ${code}` }).first();
    if (await item.count() > 0) {
      const cb = item.locator('material-checkbox').first();
      const isChecked = await cb.getAttribute('aria-checked') === 'true';
      if (!isChecked) {
        await cb.click();
        await page.waitForTimeout(60);
      }
      selected++;
    } else {
      // Try partial match
      const items = dialog.locator('.item');
      const count = await items.count();
      let found = false;
      for (let i = 0; i < count; i++) {
        const t = await items.nth(i).textContent();
        if (t && (t.includes(`– ${code}`) || t.match(new RegExp(`–\\s*${code}\\s*$`)))) {
          const cb = items.nth(i).locator('material-checkbox');
          const isChecked = await cb.getAttribute('aria-checked') === 'true';
          if (!isChecked) await cb.click();
          selected++;
          found = true;
          break;
        }
      }
      if (!found) console.log(`  ⚠ Language code "${code}" not found in dialog`);
    }
    await page.waitForTimeout(40);
  }
  
  const verified = await dialog.locator('material-checkbox[aria-checked="true"]').count();
  console.log(`  Selected: ${selected}/${TARGET_GP_CODES.length}, Verified checked: ${verified}`);
  
  // Click Apply
  const applyBtn = dialog.locator('button:has-text("Appliquer"), button:has-text("Apply")').first();
  if (await applyBtn.count() === 0) {
    console.log('  ✗ Apply button not found');
    return false;
  }
  await applyBtn.click();
  await page.waitForTimeout(5000);
  
  // Verify dropdown appeared
  const hasDropdown = await page.evaluate(() => !!document.querySelector('language-control material-dropdown-select'));
  console.log(`  Language dropdown: ${hasDropdown ? '✓ Active' : '✗ Not active'}`);
  return hasDropdown;
}

async function switchToLanguage(page, gpCode, displayName) {
  // The dropdown button is inside language-control
  const dropdownBtn = page.locator('language-control dropdown-button, language-control [role="button"]').first();
  if (await dropdownBtn.count() === 0) {
    console.log(`  ✗ Language dropdown button not found`);
    return false;
  }
  await dropdownBtn.click();
  await page.waitForTimeout(1500);
  
  // Options appear in a listbox
  // Try to find by code first, then by display name
  const patterns = [
    `– ${gpCode}`, // "Arabe – ar"
    gpCode,
    displayName,
  ].filter(Boolean);
  
  for (const pattern of patterns) {
    const opt = page.locator(`[role="option"]:has-text("${pattern}")`).first();
    if (await opt.count() > 0) {
      await opt.click();
      await page.waitForTimeout(2000);
      return true;
    }
  }
  
  // Get all options for debugging
  const opts = await page.evaluate(() => {
    return Array.from(document.querySelectorAll('[role="option"]')).map(o => o.textContent.trim().substring(0, 50));
  });
  console.log(`  ✗ Could not find "${gpCode}" in options. Available: ${opts.slice(0, 5).join(' | ')}`);
  return false;
}

(async () => {
  console.log('╔═══════════════════════════════════════════════════╗');
  console.log('║  LUNA Play Store — Fill All 39 Translation Locales ║');
  console.log('╚═══════════════════════════════════════════════════╝\n');

  const browser = await chromium.connectOverCDP(`http://localhost:${CDP_PORT}`);
  const context = browser.contexts()[0];
  let page = context.pages().find(p => p.url().includes('play.google.com')) || context.pages()[0];
  
  // Navigate to listing page
  console.log('Navigating to main store listing...');
  await page.goto(
    `https://play.google.com/console/u/0/developers/${DEVELOPER_ID}/app/${APP_ID}/main-store-listing`,
    { waitUntil: 'load', timeout: 30000 }
  );
  await page.waitForTimeout(4000);
  
  // Check if language dropdown already exists
  let hasDropdown = await page.evaluate(() => !!document.querySelector('language-control material-dropdown-select'));
  
  if (!hasDropdown) {
    console.log('Language dropdown not present. Adding languages...');
    hasDropdown = await addLanguages(page);
    if (!hasDropdown) {
      console.error('Failed to add languages. Exiting.');
      await browser.close();
      process.exit(1);
    }
  } else {
    console.log('✓ Language dropdown already present');
  }
  
  // Build the list of languages to process
  let toLProcess = [...TARGET_GP_CODES];
  
  if (SINGLE) {
    // Find the GP code for this locale
    const gpCode = Object.entries(GP_TO_FOLDER).find(([k, v]) => v === SINGLE || k === SINGLE)?.[0];
    if (!gpCode) {
      console.error(`Unknown locale: ${SINGLE}`);
      process.exit(1);
    }
    toLProcess = [gpCode];
  }
  
  if (START_FROM) {
    const gpCode = Object.entries(GP_TO_FOLDER).find(([k, v]) => v === START_FROM || k === START_FROM)?.[0];
    const idx = toLProcess.indexOf(gpCode);
    if (idx >= 0) {
      toLProcess = toLProcess.slice(idx);
      console.log(`Starting from ${START_FROM} (${toLProcess.length} languages to fill)`);
    }
  }
  
  console.log(`\nFilling ${toLProcess.length} translations...\n`);
  
  let done = 0;
  let failed = [];
  
  for (const gpCode of toLProcess) {
    const folder = GP_TO_FOLDER[gpCode];
    if (!folder) { console.log(`⚠ No folder mapping for ${gpCode}`); continue; }
    
    const title  = readMeta(folder, 'title.txt');
    const short  = readMeta(folder, 'short_description.txt');
    const full   = readMeta(folder, 'full_description.txt');
    
    if (!title && !short && !full) {
      console.log(`⏭  Skipping ${gpCode} (folder: ${folder}) — no metadata`);
      continue;
    }
    
    console.log(`\n[${done + 1}/${toLProcess.length}] ${gpCode} (${folder})`);
    
    // Switch to this language
    const switched = await switchToLanguage(page, gpCode, folder);
    if (!switched) {
      console.log(`  ✗ Failed to switch to ${gpCode}`);
      failed.push(gpCode);
      continue;
    }
    
    await waitForAngular(page);
    
    // Fill fields
    if (title)  await fillField(page, title, 'name');
    if (short)  await fillField(page, short, 'short');
    if (full)   await fillField(page, full, 'full');
    
    // Save
    const saved = await clickSave(page);
    if (!saved) {
      console.log(`  ✗ Failed to save ${gpCode}`);
      failed.push(gpCode);
    } else {
      done++;
    }
    
    await page.waitForTimeout(500);
  }
  
  console.log(`\n╔════════════════════════════════════════╗`);
  console.log(`║  DONE: ${done}/${toLProcess.length} locales filled`);
  if (failed.length) {
    console.log(`║  FAILED: ${failed.join(', ')}`);
  }
  console.log(`╚════════════════════════════════════════╝`);
  
  await browser.close();
})();
