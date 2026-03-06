# LUNA — Contexte Claude (télégraphique)

> Suivi cycle menstruel · Privacy-first · iOS + Android · Rust core partagé

---

## STACK

| | |
|--|--|
| Core | Rust + UniFFI 0.28 (proc-macros, no .udl) |
| DB | SQLCipher (rusqlite bundled-sqlcipher-vendored-openssl) |
| Crypto | Argon2id(64MB/3iter/4t)→AES-256-GCM · HKDF-SHA256 sous-clés · zstd BLOB |
| iOS | SwiftUI iOS 16+ · Keychain (Security.framework, ThisDeviceOnly) |
| Android | Kotlin Views · Android Keystore AES-256-GCM · minSdk **23** (6.0 Marshmallow) |
| i18n | 40 langues · xcstrings (FR source) · strings.xml · RTL complet |
| a11y | WCAG 2.2 AA · Calm Mode · reduceMotion · TalkBack/VoiceOver |

---

## STORES — DÉPLOYÉ

### Android — Google Play
- **Package** : `com.macaron.luna` (namespace source : `app.luna` inchangé)
- **App ID Play Console** : `4973061748192418870` · Developer : `6295830866613067582`
- **Status** : Tests internes ✅ · v1.0.0 (versionCode 1) · 9.8 MB AAB · 6 mars 2026
- **URL** : `play.google.com/console/.../app/4973061748192418870`
- **Keystore** : `android-app/keystore/luna-release.jks` · alias `luna` · pw `luna_store_2026`
- **Key props** : `android-app/key.properties` (non commité)
- **Zéro permissions santé** : READ/WRITE_MENSTRUATION supprimées · aucun partage externe

### iOS — App Store Connect / TestFlight
- **Bundle ID** : `com.macaron.luna` · Team : `P36X572LL9`
- **App ID ASC** : `6760126548`
- **Status** : TestFlight internal ✅ · v0.1.0 build 1 · 4.9 MB IPA · 6 mars 2026
- **Cert** : `Apple Distribution: sylvain legland (P36X572LL9)`
- **Provisioning** : `luna-appstore-distribution.mobileprovision`
- **ASC API Key** : `~/.appstoreconnect/private_keys/AuthKey_48GLJZYX5K.p8` · issuer `69a6de74-3cdf-47e3-e053-5b8c7c11a4d1`

### Fastlane
- `fastlane ios build` → gym → `/tmp/fastlane_build/LUNA.ipa`
- `fastlane ios upload_testflight` → pilot → TestFlight internal
- `fastlane ios release` → build + upload_testflight en une commande
- Pour Android : `./gradlew bundleRelease` + CDP script `scripts/release_internal_test.js`

### Scripts CDP (Play Store automation)
- `scripts/upload_play_assets.js` — upload screenshots + FG 40 locales (✅ terminé)
- `scripts/release_internal_test.js` — upload AAB + release notes → track internal-testing
- Chrome CDP port **18800** (`chrome --remote-debugging-port=18800`)
- Trick filechooser : 1 `page.goto()` par upload (bug CDP multi-upload)

### Assets store
- **Screenshots** : `fastlane/screenshots/` · 40 locales · 6 phones + 7" + 10" tablettes
- **Feature Graphics** : `fastlane/screenshots/` · 1024×500 · 40 locales
- **Icon iOS** : `ios-app/LunaApp/Resources/Assets.xcassets/AppIcon.appiconset/` · 14 tailles · **sans canal alpha** (Apple rejette alpha)
- **Icon Android** : `android-app/app/src/main/res/` · mipmap-{mdpi..xxxhdpi}
- **Privacy page** : `https://privacy.macaron-software.com/luna`

---

## BUILD ✅ (2026-03-05 · commit 2f5a3e5)

```bash
cd _FLO
cargo test                          # 23/23 ✅

# iOS sim (iPhone 16 Pro · 7A806776-2927-46EF-98F6-4D852C5AC671)
cd ios-app && xcodegen generate
xcodebuild build -scheme LunaApp \
  -destination 'platform=iOS Simulator,id=7A806776-2927-46EF-98F6-4D852C5AC671' \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO ONLY_ACTIVE_ARCH=YES

# iOS release IPA (fastlane)
fastlane ios build           # → /tmp/fastlane_build/LUNA.ipa
fastlane ios upload_testflight

# Android AAB release
cd android-app && ./gradlew bundleRelease
# → app/build/outputs/bundle/release/app-release.aab

# Android JNI (si Rust change)
ANDROID_NDK_HOME=~/Library/Android/sdk/ndk/27.2.12479018 \
  cargo ndk --target arm64-v8a --output-dir android-app/app/src/main/jniLibs -- build --release

# Rebuild bindings (si API Rust change)
cargo build --release
cargo run -p uniffi-bindgen -- generate \
  --library target/release/libluna_core.dylib \
  --language swift --out-dir ios-app/LunaApp/Generated
cp ios-app/LunaApp/Generated/luna_coreFFI.modulemap \
   ios-app/LunaApp/Generated/module.modulemap
cargo run -p uniffi-bindgen -- generate \
  --library target/release/libluna_core.dylib \
  --language kotlin --out-dir android-app/app/src/main/generated
```

---

## API RUST (UniFFI)

```rust
LunaEngine::open_vault(db_path, pin) -> Result<LunaEngine>
.log_day(DailyLog)           .get_log(date) -> Option<DailyLog>
.get_cycles(limit)           .start_cycle(date)  .end_cycle(id, date)
.predict_next() -> Prediction  .get_cycle_summary() -> CycleSummary
.change_pin(old, new)        .panic_wipe()        .export_encrypted_backup(pin)
vault_exists(db_path) -> bool
```

### DailyLog (types.rs)
```
id, date, symptoms: Vec<String>,
mood?: u8(1-5), energy?: u8(1-5), sleep_quality?: u8(1-5), weight_kg?: f64,
bbt?: f64, lh_test?: str, cervical_mucus?: str, sexual_activity?: str,
flow?: str, notes?: str
```
Symptoms : 43 constantes (cramps, SPM, ovulation, folliculaire, générale, péri-ménopause)

### Storage
- symptoms → serde_json → zstd compress → SQLCipher BLOB
- décompression avec fallback `unwrap_or_default()` (compat)

---

## FICHIERS CLÉS

```
luna-core/src/
  api.rs              UniFFI public (LunaEngine)
  engine/types.rs     DailyLog, Cycle, Prediction, CycleSummary, symptoms::*
  engine/prediction.rs PredictionEngine (calendar|bbt|lh|combined)
  vault/crypto.rs     derive_key, encrypt/decrypt, compress/decompress_blob, secure_zero
  vault/database.rs   SQLCipher · upsert_log · get_log · get_logs_range
  error.rs            LunaError (8 variants)

ios-app/
  project.yml                      xcodegen config — regénérer xcodeproj si modifié
  LunaApp/Generated/               NE PAS ÉDITER (luna_core.swift, .a, .modulemap)
  LunaApp/Views/                   OnboardingView, LockView, HomeView, Calendar,
                                   Insights, Settings, LogSheetView, RootView
  LunaApp/Resources/Localizable.xcstrings  100+ clés, 40 langues
  LunaApp/Services/KeychainService.swift   SecItemAdd/CopyMatching/Delete
  LunaApp/Info.plist               UILaunchScreen dict · ITSAppUsesNonExemptEncryption=false

android-app/app/src/main/
  AndroidManifest.xml              ZÉRO permissions réseau + ZÉRO permissions santé
  generated/uniffi/luna_core/luna_core.kt  NE PAS ÉDITER
  jniLibs/{arm64-v8a,x86_64}/libluna_core.so
  kotlin/app/luna/
    LunaApplication.kt             System.loadLibrary("luna_core")
    services/VaultService.kt       singleton LunaEngine
    services/KeystoreService.kt    Keystore AES-256-GCM
    ui/{LockActivity, OnboardingActivity, MainActivity}.kt
    ui/{LogBottomSheet, SettingsActivity}.kt
  res/values/strings.xml           40 langues
  res/drawable/ic_luna_*.xml       11 icônes Vector
  build.gradle.kts                 applicationId="com.macaron.luna" · namespace="app.luna"

fastlane/
  Appfile    package_name "com.macaron.luna" · app_identifier "com.macaron.luna"
  Fastfile   lanes: ios build · upload_testflight · release · android upload_internal
  metadata/  fiches store 40 locales
  screenshots/ 40 locales · phone + tablettes + feature graphic
```

---

## UI — RÈGLES

- **Zéro emoji dans l'interface** — MoodPicker = cercles numériques 1-5, logo = ImageView vectoriel
- Light/Dark auto (`preferredColorScheme(nil)` · AppBackground = #FAFAFA/#0D0A14)
- `LockBackground` toujours sombre (lock screen) · `AppBackground` pour onboarding/home
- Calm Mode (UserDefaults `calm_mode`) → masque prédictions, affiche CalmModeBanner
- `@Environment(\.accessibilityReduceMotion)` → désactive animations spring

---

## PRIVACY — VÉRIFIÉ ✅

- Zéro `INTERNET` permission · zéro URLSession/reqwest · zéro Firebase/Analytics
- **Zéro permissions santé** Android (READ/WRITE_MENSTRUATION supprimées)
- Zéro HealthConnect · pas de partage Google · données 100% locales
- DB chiffrée SQLCipher · clé Argon2id · nonce CSPRNG unique · secrecy::SecretVec zeroize
- iOS Keychain `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`
- Android Keystore hardware-backed AES-256-GCM
- Panic wipe (`panic_wipe()`) · export backup AES-256-GCM seul
- Privacy page : `https://privacy.macaron-software.com/luna` (sans emoji, SVG Feather)

---

## ACCEPTANCE CRITERIA

| Critère | |
|---------|--|
| Zéro réseau | ✅ |
| DB chiffrée AES-256 + Argon2id | ✅ |
| iOS Keychain + Android Keystore | ✅ |
| Panic wipe | ✅ |
| Backup chiffré | ✅ API (UI partielle) |
| iOS TestFlight | ✅ v0.1.0 build 1 |
| Android Play Store internal | ✅ v1.0.0 |
| Rust 23 tests | ✅ |
| i18n 40 langues · AR RTL · DE · JA | ✅ testé sim |
| Light/Dark auto | ✅ |
| zstd BLOB compression | ✅ |
| Calm Mode + reduceMotion | ✅ |
| Zéro emoji UI | ✅ |
| minSdk Android 23 | ✅ |
| sleep_quality + weight_kg | ✅ |
| Zéro permissions santé Android | ✅ |
| Icônes iOS sans alpha | ✅ |
| Parcours UI end-to-end | ⚠️ partiel |

---

## GAPS RESTANTS

Haute priorité : notifications locales · mode TTC/grossesse
Moyenne : HealthKit bridge (iOS only, opt-in) · export CSV · biométrie · pilule rappel · graphiques tendance
Basse : Apple Watch · Wear OS

---

## GOTCHAS

- UniFFI : library pas binary → wrapper `uniffi-bindgen/` obligatoire
- `onChange(of:) { new in }` iOS 16 (un param) · deux params = iOS 17+
- `NavigationStack` + `.presentationDetents` = iOS 16 min (pas de downgrade possible)
- Android Material3 1.12 : `android:colorBackground` (avec préfixe) · `fillColor="@android:color/transparent"`
- SQLCipher Android : `bundled-sqlcipher-vendored-openssl` · NDK 27.2 Rosetta2 toolchain
- Émulateur Android : `-gpu swiftshader_indirect` · attendre 60s avant `adb devices`
- i18n sim : `xcrun simctl launch $SIM com.macaron.luna -AppleLanguages "(ar)" -AppleLocale "ar_SA"`
- **Play Store** : `app.luna` pris par un tiers → applicationId changé en `com.macaron.luna` (namespace source inchangé)
- **App Store** : icône avec canal alpha → Apple rejette (supprimer avec ImageMagick `magick icon.png -background white -alpha remove -alpha off icon.png`)
- **App Store** : `UILaunchStoryboardName` vide → utiliser `UILaunchScreen` dict (iOS 14+)
- **App Store** : `ITSAppUsesNonExemptEncryption` doit être `false` (AES données locales = exempt EAR)
- CDP filechooser : 1 `page.goto()` par upload (multi-upload = filechooser event perdu)

---

## COMMANDES RAPIDES

```bash
cargo test -p luna-core                                    # tests Rust
xcrun simctl io 7A806776-... screenshot /tmp/s.png        # screenshot iOS
xcrun simctl ui 7A806776-... appearance dark|light        # toggle theme
adb -s emulator-5554 shell logcat -d | grep app.luna      # logcat Android

# Re-déployer Android
cd android-app && ./gradlew bundleRelease
node scripts/release_internal_test.js   # CDP → Play Console internal

# Re-déployer iOS
fastlane ios release                    # build + TestFlight en une commande
```

---

## BENCHMARK vs CONCURRENTS

### Features implémentées

| Feature | Flo | Clue | NatCycles | **LUNA** |
|---------|-----|------|-----------|---------|
| Période (date/durée/flux) | Oui | Oui | Oui | **Oui** |
| Symptômes catégorisés | Partiel | Partiel | Non | **43** (mens/SPM/ovul/follicul/péri-méno) |
| Humeur 1-5 | Emoji | Emoji | Non | **Oui** (cercles numériques) |
| Energie 1-5 | Non | Oui | Non | **Oui** |
| Sommeil 1-5 | Oui | Oui | Non | **Oui** |
| Poids (kg) | Oui Premium | Non | Non | **Oui** |
| BBT (température basale) | Oui | Oui | Oui | **Oui** |
| Test LH ovulation | Oui | Oui | Oui | **Oui** |
| Mucus cervical (5 types) | Oui | Oui | Oui | **Oui** |
| Activité sexuelle | Oui | Oui | Non | **Oui** |
| Notes libres | Oui | Oui | Oui | **Oui** |
| Prédictions cycle/ovulation | IA cloud | IA cloud | Algo serveur | **On-device** |
| Calendrier | Oui | Oui | Oui | **Oui** |
| Insights / statistiques | Oui | Oui | Oui | **Oui** |
| Export backup chiffré | Non | Non | Non | **Oui** AES-256 |
| Dark mode auto | Oui | Oui | Oui | **Oui** |
| i18n | 22 langues | 15 | 12 | **40 langues** |
| RTL (arabe, hébreu, persan) | Partiel | Non | Non | **Oui** (testé) |
| WCAG 2.2 AA | Partiel | Partiel | Non | **Oui** |
| Mode Calm (psy a11y) | Non | Non | Non | **Oui** (unique) |
| Reduce Motion | Non | Non | Non | **Oui** |
| PIN + Keychain/Keystore | Non | Non | Non | **Oui** |
| Panic wipe | Non | Non | Non | **Oui** (unique) |
| Zéro réseau / zéro serveur | Non | Non | Non | **Oui** |
| Données revendables | Oui (Flo) | Non | Non | **Impossible** |
| Zéro emoji UI | Non | Non | Non | **Oui** |

### Gaps vs concurrents — backlog priorisé

| Feature | Priorité |
|---------|----------|
| Notifications locales (rappel période, ovulation) | Haute |
| Mode TTC / grossesse (test hCG, suivi) | Haute |
| HealthKit (iOS only, opt-in) | Moyenne |
| Authentification biométrique (FaceID/empreinte) | Moyenne |
| Export CSV / PDF | Moyenne |
| Rappel pilule / contraception | Moyenne |
| Graphiques tendance (BBT, poids, cycle) | Moyenne |
| Mode péri-ménopause dédié | Basse |
| Apple Watch / Wear OS companion | Basse |

### Compatibilité appareils

| Plateforme | Min OS | Couverture |
|------------|--------|------------|
| Android | **API 23** (6.0 Marshmallow, oct 2015) | ~98% appareils actifs |
| iOS | **16.0** (sept 2022) | ~95% iPhones actifs |
| ABI Android | arm64-v8a · armeabi-v7a · x86_64 | 32-bit ARM inclus |

> iOS 16 minimum imposé par `NavigationStack` + `.presentationDetents` — descendre à iOS 15 nécessiterait remplacer par `NavigationView` (faible ROI, les utilisateurs iOS upgradent rapidement)


| | |
|--|--|
| Core | Rust + UniFFI 0.28 (proc-macros, no .udl) |
| DB | SQLCipher (rusqlite bundled-sqlcipher-vendored-openssl) |
| Crypto | Argon2id(64MB/3iter/4t)→AES-256-GCM · HKDF-SHA256 sous-clés · zstd BLOB |
| iOS | SwiftUI iOS 16+ · Keychain (Security.framework, ThisDeviceOnly) |
| Android | Kotlin Views · Android Keystore AES-256-GCM · minSdk **23** (6.0 Marshmallow) |
| i18n | 40 langues · xcstrings (FR source) · strings.xml · RTL complet |
| a11y | WCAG 2.2 AA · Calm Mode · reduceMotion · TalkBack/VoiceOver |

---

## BUILD ✅ (2026-03-05 · commit 2f5a3e5)

```bash
cd _FLO
cargo test                          # 23/23 ✅

# iOS sim (iPhone 16 Pro · 7A806776-2927-46EF-98F6-4D852C5AC671)
cd ios-app && xcodegen generate
xcodebuild build -scheme LunaApp \
  -destination 'platform=iOS Simulator,id=7A806776-2927-46EF-98F6-4D852C5AC671' \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO ONLY_ACTIVE_ARCH=YES

# Android (Pixel6_API34 · arm64-v8a)
ANDROID_NDK_HOME=~/Library/Android/sdk/ndk/27.2.12479018 \
  cargo ndk --target arm64-v8a --output-dir android-app/app/src/main/jniLibs -- build --release
cd android-app && ./gradlew assembleDebug

# Rebuild bindings (si API Rust change)
cargo build --release
cargo run -p uniffi-bindgen -- generate \
  --library target/release/libluna_core.dylib \
  --language swift --out-dir ios-app/LunaApp/Generated
cp ios-app/LunaApp/Generated/luna_coreFFI.modulemap \
   ios-app/LunaApp/Generated/module.modulemap
cargo run -p uniffi-bindgen -- generate \
  --library target/release/libluna_core.dylib \
  --language kotlin --out-dir android-app/app/src/main/generated
```

---

## API RUST (UniFFI)

```rust
LunaEngine::open_vault(db_path, pin) -> Result<LunaEngine>
.log_day(DailyLog)           .get_log(date) -> Option<DailyLog>
.get_cycles(limit)           .start_cycle(date)  .end_cycle(id, date)
.predict_next() -> Prediction  .get_cycle_summary() -> CycleSummary
.change_pin(old, new)        .panic_wipe()        .export_encrypted_backup(pin)
vault_exists(db_path) -> bool
```

### DailyLog (types.rs)
```
id, date, symptoms: Vec<String>,
mood?: u8(1-5), energy?: u8(1-5), sleep_quality?: u8(1-5), weight_kg?: f64,
bbt?: f64, lh_test?: str, cervical_mucus?: str, sexual_activity?: str,
flow?: str, notes?: str
```
Symptoms : 43 constantes (cramps, SPM, ovulation, folliculaire, générale, péri-ménopause)

### Storage
- symptoms → serde_json → zstd compress → SQLCipher BLOB
- décompression avec fallback `unwrap_or_default()` (compat)

---

## FICHIERS CLÉS

```
luna-core/src/
  api.rs              UniFFI public (LunaEngine)
  engine/types.rs     DailyLog, Cycle, Prediction, CycleSummary, symptoms::*
  engine/prediction.rs PredictionEngine (calendar|bbt|lh|combined)
  vault/crypto.rs     derive_key, encrypt/decrypt, compress/decompress_blob, secure_zero
  vault/database.rs   SQLCipher · upsert_log · get_log · get_logs_range
  error.rs            LunaError (8 variants)

ios-app/
  project.yml                      xcodegen config — regénérer xcodeproj si modifié
  LunaApp/Generated/               NE PAS ÉDITER (luna_core.swift, .a, .modulemap)
  LunaApp/Views/                   OnboardingView, LockView, HomeView, Calendar,
                                   Insights, Settings, LogSheetView, RootView
  LunaApp/Resources/Localizable.xcstrings  100+ clés, 40 langues
  LunaApp/Services/KeychainService.swift   SecItemAdd/CopyMatching/Delete

android-app/app/src/main/
  generated/uniffi/luna_core/luna_core.kt  NE PAS ÉDITER
  jniLibs/{arm64-v8a,x86_64}/libluna_core.so
  kotlin/app/luna/
    LunaApplication.kt             System.loadLibrary("luna_core")
    services/VaultService.kt       singleton LunaEngine
    services/KeystoreService.kt    Keystore AES-256-GCM
    ui/{LockActivity, OnboardingActivity, MainActivity}.kt
    ui/{LogBottomSheet, SettingsActivity}.kt
  res/values/strings.xml           40 langues
  res/drawable/ic_luna_*.xml       11 icônes Vector
```

---

## UI — RÈGLES

- **Zéro emoji dans l'interface** — MoodPicker = cercles numériques 1-5, logo = ImageView vectoriel
- Light/Dark auto (`preferredColorScheme(nil)` · AppBackground = #FAFAFA/#0D0A14)
- `LockBackground` toujours sombre (lock screen) · `AppBackground` pour onboarding/home
- Calm Mode (UserDefaults `calm_mode`) → masque prédictions, affiche CalmModeBanner
- `@Environment(\.accessibilityReduceMotion)` → désactive animations spring

---

## PRIVACY — VÉRIFIÉ ✅

- Zéro `INTERNET` permission · zéro URLSession/reqwest · zéro Firebase/Analytics
- DB chiffrée SQLCipher · clé Argon2id · nonce CSPRNG unique · secrecy::SecretVec zeroize
- iOS Keychain `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`
- Android Keystore hardware-backed AES-256-GCM
- Panic wipe (`panic_wipe()`) · export backup AES-256-GCM seul

---

## ACCEPTANCE CRITERIA

| Critère | |
|---------|--|
| Zéro réseau | ✅ |
| DB chiffrée AES-256 + Argon2id | ✅ |
| iOS Keychain + Android Keystore | ✅ |
| Panic wipe | ✅ |
| Backup chiffré | ✅ API (UI partielle) |
| iOS build sim | ✅ iPhone 16 Pro |
| Android build emu | ✅ Pixel6_API34 |
| Rust 23 tests | ✅ |
| i18n 40 langues · AR RTL · DE · JA | ✅ testé sim |
| Light/Dark auto | ✅ |
| zstd BLOB compression | ✅ |
| Calm Mode + reduceMotion | ✅ |
| Zéro emoji UI | ✅ |
| minSdk Android 23 | ✅ |
| sleep_quality + weight_kg | ✅ |
| Parcours UI end-to-end | ⚠️ partiel |

---

## GAPS RESTANTS

Haute priorité : notifications locales · mode TTC/grossesse
Moyenne : HealthKit/HealthConnect bridge · export CSV · biométrie · pilule rappel · graphiques tendance
Basse : Apple Watch · Wear OS

---

## GOTCHAS

- UniFFI : library pas binary → wrapper `uniffi-bindgen/` obligatoire
- `onChange(of:) { new in }` iOS 16 (un param) · deux params = iOS 17+
- `NavigationStack` + `.presentationDetents` = iOS 16 min (pas de downgrade possible)
- Android Material3 1.12 : `android:colorBackground` (avec préfixe) · `fillColor="@android:color/transparent"`
- SQLCipher Android : `bundled-sqlcipher-vendored-openssl` · NDK 27.2 Rosetta2 toolchain
- Émulateur Android : `-gpu swiftshader_indirect` · attendre 60s avant `adb devices`
- i18n sim : `xcrun simctl launch $SIM com.macaron.luna -AppleLanguages "(ar)" -AppleLocale "ar_SA"`

---

## COMMANDES RAPIDES

```bash
cargo test -p luna-core                                    # tests Rust
xcrun simctl io 7A806776-... screenshot /tmp/s.png        # screenshot iOS
xcrun simctl ui 7A806776-... appearance dark|light        # toggle theme
adb -s emulator-5554 shell logcat -d | grep app.luna      # logcat Android
```

---

## BENCHMARK vs CONCURRENTS

### Features implémentées

| Feature | Flo | Clue | NatCycles | **LUNA** |
|---------|-----|------|-----------|---------|
| Période (date/durée/flux) | Oui | Oui | Oui | **Oui** |
| Symptômes catégorisés | Partiel | Partiel | Non | **43** (mens/SPM/ovul/follicul/péri-méno) |
| Humeur 1-5 | Emoji | Emoji | Non | **Oui** (cercles numériques) |
| Energie 1-5 | Non | Oui | Non | **Oui** |
| Sommeil 1-5 | Oui | Oui | Non | **Oui** |
| Poids (kg) | Oui Premium | Non | Non | **Oui** |
| BBT (température basale) | Oui | Oui | Oui | **Oui** |
| Test LH ovulation | Oui | Oui | Oui | **Oui** |
| Mucus cervical (5 types) | Oui | Oui | Oui | **Oui** |
| Activité sexuelle | Oui | Oui | Non | **Oui** |
| Notes libres | Oui | Oui | Oui | **Oui** |
| Prédictions cycle/ovulation | IA cloud | IA cloud | Algo serveur | **On-device** |
| Calendrier | Oui | Oui | Oui | **Oui** |
| Insights / statistiques | Oui | Oui | Oui | **Oui** |
| Export backup chiffré | Non | Non | Non | **Oui** AES-256 |
| Dark mode auto | Oui | Oui | Oui | **Oui** |
| i18n | 22 langues | 15 | 12 | **40 langues** |
| RTL (arabe, hébreu, persan) | Partiel | Non | Non | **Oui** (testé) |
| WCAG 2.2 AA | Partiel | Partiel | Non | **Oui** |
| Mode Calm (psy a11y) | Non | Non | Non | **Oui** (unique) |
| Reduce Motion | Non | Non | Non | **Oui** |
| PIN + Keychain/Keystore | Non | Non | Non | **Oui** |
| Panic wipe | Non | Non | Non | **Oui** (unique) |
| Zéro réseau / zéro serveur | Non | Non | Non | **Oui** |
| Données revendables | Oui (Flo) | Non | Non | **Impossible** |
| Zéro emoji UI | Non | Non | Non | **Oui** |

### Gaps vs concurrents — backlog priorisé

| Feature | Priorité |
|---------|----------|
| Notifications locales (rappel période, ovulation) | Haute |
| Mode TTC / grossesse (test hCG, suivi) | Haute |
| HealthKit (iOS) / HealthConnect (Android) bridge | Moyenne |
| Authentification biométrique (FaceID/empreinte) | Moyenne |
| Export CSV / PDF | Moyenne |
| Rappel pilule / contraception | Moyenne |
| Graphiques tendance (BBT, poids, cycle) | Moyenne |
| Mode péri-ménopause dédié | Basse |
| Apple Watch / Wear OS companion | Basse |

### Compatibilité appareils

| Plateforme | Min OS | Couverture |
|------------|--------|------------|
| Android | **API 23** (6.0 Marshmallow, oct 2015) | ~98% appareils actifs |
| iOS | **16.0** (sept 2022) | ~95% iPhones actifs |
| ABI Android | arm64-v8a · armeabi-v7a · x86_64 | 32-bit ARM inclus |

> iOS 16 minimum imposé par `NavigationStack` + `.presentationDetents` — descendre à iOS 15 nécessiterait remplacer par `NavigationView` (faible ROI, les utilisateurs iOS upgradent rapidement)

