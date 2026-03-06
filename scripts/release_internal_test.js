#!/usr/bin/env node
/**
 * release_internal_test.js
 *
 * Uploads AAB to Play Store internal testing track via CDP.
 * Navigates to the existing draft release and:
 *   1. Uploads app-release.aab
 *   2. Fills release name + release notes (all 40 langs)
 *   3. Saves and submits
 */

const { chromium } = require('playwright');
const path = require('path');
const fs   = require('fs');

const CDP_PORT  = 18800;
const RELEASE_URL = 'https://play.google.com/console/u/0/developers/6295830866613067582/app/4973061748192418870/tracks/internal-testing';
const AAB_PATH  = path.join(__dirname, '..', 'android-app', 'app', 'build', 'outputs', 'bundle', 'release', 'app-release.aab');

// Release notes per language (Play Console format: <lang-code>notes</lang-code>)
const NOTES = {
  'en-US': 'Initial release of LUNA - Cycle & Wellness. Track your cycle, symptoms, mood and energy. All data stays 100% private on your device — no account, no cloud, no tracking.',
  'fr-FR': 'Première version de LUNA - Cycle & Bien-être. Suivez votre cycle, symptômes, humeur et énergie. Toutes vos données restent 100% privées sur votre appareil.',
  'de-DE': 'Erste Version von LUNA - Zyklus & Wohlbefinden. Verfolgen Sie Ihren Zyklus, Symptome, Stimmung und Energie. Alle Daten bleiben 100% privat auf Ihrem Gerät.',
  'es-ES': 'Primera versión de LUNA - Ciclo y Bienestar. Rastrea tu ciclo, síntomas, estado de ánimo y energía. Todos tus datos permanecen 100% privados en tu dispositivo.',
  'es-419': 'Primera versión de LUNA - Ciclo y Bienestar. Sigue tu ciclo, síntomas, estado de ánimo y energía. Todos tus datos permanecen 100% privados en tu dispositivo.',
  'it-IT': 'Prima versione di LUNA - Ciclo e Benessere. Traccia il tuo ciclo, sintomi, umore ed energia. Tutti i dati rimangono 100% privati sul tuo dispositivo.',
  'pt-BR': 'Primeira versão do LUNA - Ciclo e Bem-estar. Acompanhe seu ciclo, sintomas, humor e energia. Todos os dados ficam 100% privados no seu dispositivo.',
  'pt-PT': 'Primeira versão do LUNA - Ciclo e Bem-estar. Acompanhe o seu ciclo, sintomas, humor e energia. Todos os dados ficam 100% privados no seu dispositivo.',
  'nl-NL': 'Eerste versie van LUNA - Cyclus & Welzijn. Volg je cyclus, symptomen, stemming en energie. Al je gegevens blijven 100% privé op je apparaat.',
  'ru-RU': 'Первый выпуск LUNA - Цикл и здоровье. Отслеживайте свой цикл, симптомы, настроение и энергию. Все данные остаются на вашем устройстве.',
  'ja-JP': 'LUNA - サイクル＆ウェルネスの最初のリリース。周期、症状、気分、エネルギーを記録。全データはデバイス上にプライベートに保存されます。',
  'ko-KR': 'LUNA - 사이클 & 웰니스의 첫 번째 릴리스. 주기, 증상, 기분, 에너지를 추적하세요. 모든 데이터는 기기에 100% 비공개로 저장됩니다.',
  'zh-CN': 'LUNA - 周期与健康首个版本。跟踪您的周期、症状、情绪和能量。所有数据100%私密存储在您的设备上。',
  'zh-TW': 'LUNA - 週期與健康首個版本。追蹤您的週期、症狀、情緒和能量。所有資料100%私密儲存在您的裝置上。',
  'ar': 'الإصدار الأول من LUNA - الدورة والصحة. تتبعي دورتك والأعراض والمزاج والطاقة. جميع البيانات خاصة 100% على جهازك.',
  'hi-IN': 'LUNA - साइकल और वेलनेस का पहला संस्करण। अपने चक्र, लक्षण, मूड और ऊर्जा को ट्रैक करें। सभी डेटा आपके डिवाइस पर 100% निजी रहता है।',
  'tr-TR': 'LUNA - Döngü ve Sağlık ilk sürümü. Döngünüzü, semptomlarınızı, ruh halinizi ve enerjinizi takip edin. Tüm veriler cihazınızda 100% gizli kalır.',
  'pl-PL': 'Pierwsze wydanie LUNA - Cykl i Wellness. Śledź swój cykl, objawy, nastrój i energię. Wszystkie dane pozostają 100% prywatne na Twoim urządzeniu.',
  'sv-SE': 'Första versionen av LUNA - Cykel & Välmående. Spåra din cykel, symptom, humör och energi. All data förblir 100% privat på din enhet.',
  'no-NO': 'Første versjon av LUNA - Syklus og Velvære. Spor syklus, symptomer, humør og energi. All data forblir 100% privat på enheten din.',
  'da-DK': 'Første udgave af LUNA - Cyklus & Velvære. Spor din cyklus, symptomer, humør og energi. Alle data forbliver 100% private på din enhed.',
  'fi-FI': 'LUNA - Sykli & Hyvinvoinnin ensimmäinen julkaisu. Seuraa sykliäsi, oireitasi, mielialaasi ja energiaasi. Kaikki tiedot pysyvät 100% yksityisinä laitteellasi.',
  'cs-CZ': 'První vydání LUNA - Cyklus a pohoda. Sledujte svůj cyklus, příznaky, náladu a energii. Všechna data zůstávají 100% soukromá na vašem zařízení.',
  'hu-HU': 'A LUNA - Ciklus és jólét első kiadása. Kövesse nyomon ciklusát, tüneteit, hangulatát és energiáját. Minden adat 100% privát marad az eszközén.',
  'ro': 'Prima versiune LUNA - Ciclu și Bunăstare. Urmăriți-vă ciclul, simptomele, starea de spirit și energia. Toate datele rămân 100% private pe dispozitivul dvs.',
  'bg': 'Първо издание на LUNA - Цикъл и здраве. Проследявайте цикъла, симптомите, настроението и енергията си. Всички данни остават 100% лични на устройството ви.',
  'el-GR': 'Πρώτη έκδοση LUNA - Κύκλος & Ευεξία. Παρακολουθήστε τον κύκλο σας, τα συμπτώματα, τη διάθεση και την ενέργειά σας. Όλα τα δεδομένα παραμένουν 100% ιδιωτικά.',
  'uk': 'Перший випуск LUNA - Цикл та здоров\'я. Відстежуйте свій цикл, симптоми, настрій та енергію. Усі дані залишаються 100% приватними на вашому пристрої.',
  'id': 'Rilis pertama LUNA - Siklus & Kesehatan. Lacak siklus, gejala, suasana hati, dan energi Anda. Semua data tetap 100% pribadi di perangkat Anda.',
  'ms-MY': 'Keluaran pertama LUNA - Kitaran & Kesihatan. Jejak kitaran, gejala, mood dan tenaga anda. Semua data kekal 100% peribadi di peranti anda.',
  'th': 'LUNA - วงจรและสุขภาพ เวอร์ชันแรก ติดตามวงจร อาการ อารมณ์ และพลังงานของคุณ ข้อมูลทั้งหมดเป็นส่วนตัว 100% บนอุปกรณ์ของคุณ',
  'vi': 'Phiên bản đầu tiên của LUNA - Chu kỳ & Sức khỏe. Theo dõi chu kỳ, triệu chứng, tâm trạng và năng lượng. Mọi dữ liệu được lưu trữ 100% riêng tư trên thiết bị.',
  'iw-IL': 'גרסה ראשונה של LUNA - מחזור ובריאות. עקבי אחר המחזור, הסימפטומים, מצב הרוח והאנרגיה. כל הנתונים נשמרים 100% פרטיים במכשיר שלך.',
  'fa': 'اولین نسخه LUNA - چرخه و سلامت. چرخه، علائم، خلق و انرژی خود را دنبال کنید. تمام داده‌ها ۱۰۰٪ خصوصی روی دستگاه شما ذخیره می‌شوند.',
  'ur': 'LUNA - سائیکل اور صحت کا پہلا ورژن۔ اپنے سائیکل، علامات، موڈ اور توانائی کو ٹریک کریں۔ تمام ڈیٹا آپ کے آلے پر 100% نجی رہتا ہے۔',
  'bn-BD': 'LUNA - সাইকেল ও সুস্থতার প্রথম সংস্করণ। আপনার চক্র, লক্ষণ, মেজাজ এবং শক্তি ট্র্যাক করুন। সমস্ত ডেটা আপনার ডিভাইসে 100% ব্যক্তিগত থাকে।',
  'ta-IN': 'LUNA - சுழற்சி & ஆரோக்கியம் முதல் வெளியீடு. உங்கள் சுழற்சி, அறிகுறிகள், மனநிலை மற்றும் ஆற்றலை கண்காணியுங்கள். அனைத்து தரவும் 100% தனிப்பட்டதாக இருக்கும்.',
  'fr-CA': 'Première version de LUNA - Cycle & Bien-être. Suivez votre cycle, symptômes, humeur et énergie. Toutes vos données restent 100% privées sur votre appareil.',
  'hr': 'Prvo izdanje LUNA - Ciklus i wellness. Pratite svoj ciklus, simptome, raspoloženje i energiju. Svi podaci ostaju 100% privatni na vašem uređaju.',
  'sk': 'Prvé vydanie LUNA - Cyklus a pohoda. Sledujte svoj cyklus, príznaky, náladu a energiu. Všetky dáta zostávajú 100% súkromné na vašom zariadení.',
};

// Build the XML-style release notes string
function buildReleaseNotes() {
  return Object.entries(NOTES).map(([lang, text]) => `<${lang}>\n${text}\n</${lang}>`).join('\n');
}

async function sleep(ms) { return new Promise(r => setTimeout(r, ms)); }

(async () => {
  console.log('╔══════════════════════════════════════════════════════╗');
  console.log('║  LUNA — Internal Test Release Upload                  ║');
  console.log('╚══════════════════════════════════════════════════════╝\n');

  const aabSize = (fs.statSync(AAB_PATH).size / 1024 / 1024).toFixed(1);
  console.log(`AAB: ${AAB_PATH} (${aabSize} MB)\n`);

  const browser = await chromium.connectOverCDP(`http://localhost:${CDP_PORT}`);
  const context = browser.contexts()[0];
  let page = context.pages().find(p => p.url().includes('play.google.com')) || context.pages()[0];

  // 1. Navigate to internal testing track
  console.log('1. Navigating to internal testing track...');
  await page.goto(RELEASE_URL, { waitUntil: 'load', timeout: 40000 });
  await sleep(3000);

  // 2. Click "Créer une release" (new release) or edit draft if present
  console.log('2. Opening release editor...');
  const draftBtn = page.locator('[debug-id="edit-draft-release-button"]');
  const createBtn = page.locator('[debug-id="create-release-button"], button:has-text("Créer une release"), button:has-text("Create release")');
  if (await draftBtn.count() > 0) {
    await draftBtn.click();
  } else if (await createBtn.count() > 0) {
    await createBtn.first().evaluate(el => el.click());
  } else {
    // Try navigating directly to new release URL
    const newReleaseUrl = RELEASE_URL.replace('/tracks/internal-testing', '/tracks/4701376161135275371/releases/new/prepare');
    await page.goto(newReleaseUrl, { waitUntil: 'load', timeout: 40000 });
  }
  await sleep(4000);
  console.log('   URL:', page.url());

  // 3. Upload AAB
  console.log('3. Uploading AAB...');
  const uploadBtn = page.locator('button.upload-button').first();
  if (await uploadBtn.count() === 0) {
    console.error('   ✗ Upload button not found');
    await page.screenshot({ path: '/tmp/upload_error.png' });
    await browser.close(); return;
  }

  const [chooser] = await Promise.all([
    page.waitForEvent('filechooser', { timeout: 10000 }),
    uploadBtn.click(),
  ]);
  await chooser.setFiles(AAB_PATH);
  console.log('   ✓ File selected, waiting for upload...');

  // Wait for AAB to finish processing (look for version code to appear)
  for (let i = 0; i < 60; i++) {
    const uploaded = await page.locator('[class*="artifact"], td:has-text("app.luna"), [class*="bundle-row"]').count();
    const err = await page.locator('[class*="error"]:visible').count();
    if (uploaded > 0) { console.log('   ✓ AAB processed'); break; }
    if (err > 0) { console.log('   ⚠ Upload error detected'); break; }
    await sleep(2000);
    process.stdout.write('.');
    if (i === 59) console.log('\n   ⚠ Timed out waiting for AAB processing');
  }
  console.log('');
  await page.screenshot({ path: '/tmp/after_upload.png' });

  // 4. Fill release name
  console.log('4. Filling release name...');
  const versionName = '1.0.0';
  const nameInput = page.locator('[debug-id="version"] textarea, [debug-id="version"] input').first();
  if (await nameInput.count() > 0) {
    await nameInput.fill(versionName);
    console.log(`   ✓ Release name: "${versionName}"`);
  }

  // 5. Fill release notes
  console.log('5. Filling release notes (40 languages)...');
  const notesInput = page.locator('[debug-id="whats-new"] textarea').first();
  if (await notesInput.count() > 0) {
    const notes = buildReleaseNotes();
    await notesInput.fill(notes);
    console.log(`   ✓ Release notes filled (${Object.keys(NOTES).length} languages)`);
  } else {
    console.log('   ⚠ Release notes textarea not found');
  }

  await sleep(1000);

  // 6. Click "Suivant" (Next → review)
  console.log('6. Clicking Next...');
  const nextBtn = page.locator('[debug-id="review-button"]').first();
  if (await nextBtn.count() > 0 && await nextBtn.isEnabled()) {
    await nextBtn.click();
    await sleep(4000);
    console.log('   ✓ On review page');
    await page.screenshot({ path: '/tmp/review_page.png' });
  } else {
    // Save as draft first
    console.log('   ⚠ Next button not enabled, saving as draft...');
    await page.locator('[debug-id="save-button"]').first().click();
    await sleep(3000);
    console.log('   ✓ Saved as draft');
    await page.screenshot({ path: '/tmp/saved_draft.png' });
    await browser.close(); return;
  }

  // 7. On review page: click "Lancer le déploiement pour tests internes"
  console.log('7. Starting rollout...');
  const rolloutBtn = page.locator('button:has-text("Lancer le déploiement"), button:has-text("Start rollout"), button:has-text("Envoyer")').first();
  if (await rolloutBtn.count() > 0) {
    await rolloutBtn.click();
    await sleep(2000);
    // Confirm dialog
    const confirmBtn = page.locator('[role="dialog"] button:has-text("Lancer"), [role="dialog"] button:has-text("OK"), [role="dialog"] button:has-text("Confirmer")').first();
    if (await confirmBtn.count() > 0) {
      await confirmBtn.click();
      await sleep(2000);
    }
    console.log('   ✓ Internal test release launched!');
  } else {
    console.log('   Page text:', await page.locator('[debug-id="content"]').first().innerText().catch(() => '?'));
    await page.screenshot({ path: '/tmp/review_debug.png' });
  }

  await page.screenshot({ path: '/tmp/final_state.png' });
  console.log('\n✅ Done! Check /tmp/final_state.png for result.');
  await browser.close();
})();
