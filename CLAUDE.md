# LUNA — Contexte Compressé pour Claude

> App de suivi de cycle menstruel · Privacy-first · iOS + Android · Rust core

---

## ARCHITECTURE

```
_FLO/
  luna-core/          ← Noyau Rust partagé (UniFFI 0.28) — toute la logique métier
  ios-app/            ← SwiftUI (iOS 16+, Xcode 26)
  android-app/        ← Kotlin + Views (Android API 26+, AGP 8.10)
  uniffi-bindgen/     ← Helper binary pour générer les bindings
  luna-design-system/ ← Tokens, docs, icônes Feather
  docs/               ← Science, benchmark, UX research
```

### Stack technique
| Couche | Techno |
|--------|--------|
| Core métier | Rust (UniFFI 0.28, proc-macros, no .udl) |
| Chiffrement DB | SQLCipher (rusqlite bundled-sqlcipher-vendored-openssl) |
| Dérivation clé | Argon2id (64MB, 3 iter, 4 threads) → AES-256-GCM |
| Backup chiffré | AES-256-GCM + HKDF-SHA256 (sous-clés distinctes) |
| iOS UI | SwiftUI + Keychain (`Security.framework`, `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`) |
| Android UI | Kotlin Views (ViewBinding) + Android Keystore AES-256-GCM |
| Bindings | UniFFI Swift + Kotlin (générés depuis dylib macOS) |
| i18n | 40 langues (xcstrings iOS, strings.xml Android) — FR source |
| a11y | WCAG 2.2 AA (TalkBack/VoiceOver, RTL, Dynamic Type) |

---

## BUILD STATE ✅

### Rust core
```bash
cd _FLO && cargo test    # 23/23 tests passent
```

### iOS — BUILD SUCCEEDED ✅
```bash
# Prérequis : xcodegen installé (/opt/homebrew/bin/xcodegen)
cd _FLO

# 1. Build lib iOS sim (si API change)
cargo build --release --target aarch64-apple-ios-sim
cp target/aarch64-apple-ios-sim/release/libluna_core.a ios-app/LunaApp/Generated/

# 2. Régénérer bindings (si API Rust change)
cargo build --release
cargo run -p uniffi-bindgen -- generate \
  --library target/release/libluna_core.dylib \
  --language swift --out-dir ios-app/LunaApp/Generated
cp ios-app/LunaApp/Generated/luna_coreFFI.modulemap \
   ios-app/LunaApp/Generated/module.modulemap

# 3. Build Xcode
cd ios-app && xcodegen generate   # regénère .xcodeproj
xcodebuild build -scheme LunaApp \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -configuration Debug CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO

# 4. Install + run
xcrun simctl install booted "$(find ios-app/build -name 'LunaApp.app' | head -1)"
xcrun simctl launch booted com.macaron.luna
```

**Simulateur actif** : iPhone 16 Pro · UUID `7A806776-2927-46EF-98F6-4D852C5AC671`
**App tournant** : `UIKitApplication:com.macaron.luna` (onboarding step 1 visible)

### Android — BUILD SUCCEEDED ✅
```bash
# Prérequis : cargo-ndk, Android NDK 27.2.12479018, Gradle 8.10.2+
cd _FLO

# 1. Build .so arm64 (émulateur ARM64)
ANDROID_NDK_HOME=~/Library/Android/sdk/ndk/27.2.12479018 \
  cargo ndk --target arm64-v8a \
  --output-dir android-app/app/src/main/jniLibs \
  -- build --release

# 2. Build .so x86_64 (si besoin émulateur x86)
ANDROID_NDK_HOME=~/Library/Android/sdk/ndk/27.2.12479018 \
  cargo ndk --target x86_64 \
  --output-dir android-app/app/src/main/jniLibs \
  -- build --release

# 3. Régénérer bindings Kotlin (si API Rust change)
cargo build --release
cargo run -p uniffi-bindgen -- generate \
  --library target/release/libluna_core.dylib \
  --language kotlin \
  --out-dir android-app/app/src/main/generated

# 4. Build APK
cd android-app && ./gradlew assembleDebug

# 5. Run émulateur
~/Library/Android/sdk/emulator/emulator -avd Pixel6_API34 \
  -gpu swiftshader_indirect -no-audio -no-boot-anim > /tmp/emu.log 2>&1 &
sleep 60 && adb install -r app/build/outputs/apk/debug/app-debug.apk
adb shell am start -a android.intent.action.MAIN \
  -c android.intent.category.LAUNCHER -n app.luna/.ui.LockActivity
```

**Émulateur** : `Pixel6_API34` (ARM64, API 34)  
**App tournant** : LockActivity visible (PIN keyboard + lune jaune)

---

## API RUST PUBLIQUE (UniFFI)

```rust
// Constructeur (companion object Kotlin / static Swift)
LunaEngine::open_vault(db_path: String, pin: String) -> Result<LunaEngine, LunaError>

// Journalisation
fn log_day(&self, log: DailyLog) -> Result<(), LunaError>
fn get_log(&self, date: String) -> Result<Option<DailyLog>, LunaError>

// Cycles
fn get_cycles(&self, limit: u32) -> Result<Vec<Cycle>, LunaError>
fn start_cycle(&self, start_date: String) -> Result<Cycle, LunaError>
fn end_cycle(&self, cycle_id: String, end_date: String) -> Result<(), LunaError>

// Prédictions & stats
fn predict_next(&self) -> Result<Prediction, LunaError>
fn get_cycle_summary(&self) -> Result<CycleSummary, LunaError>

// Sécurité
fn change_pin(&self, old_pin: String, new_pin: String) -> Result<(), LunaError>
fn panic_wipe(&self) -> Result<(), LunaError>                  // → LunaError::WipedSuccessfully
fn export_encrypted_backup(&self, pin: String) -> Result<Vec<u8>, LunaError>

// Utilitaire (top-level)
vault_exists(db_path: String) -> bool
```

### Types de données
```
Cycle        { id, start_date, end_date?, period_length?, notes? }
DailyLog     { id, date, symptoms[], mood?, energy?, bbt?, lh_test?,
               cervical_mucus?, sexual_activity?, flow?, notes? }
Prediction   { next_period_start, confidence_days, fertile_window_start,
               fertile_window_end, ovulation_day?, algorithm, confidence_score }
CycleSummary { total_cycles, average_cycle_length, average_period_length,
               min/max_cycle_length, cycle_std_dev, regularity }
LunaError    { WrongPin, DatabaseCorrupted, CryptoError, IoError, InvalidData,
               WipedSuccessfully, VaultNotOpen, CycleNotFound }
```

---

## AUDIT PRIVACY ✅

### Zero données captées — VÉRIFIÉ
| Check | Status | Preuve |
|-------|--------|--------|
| Pas de `INTERNET` permission Android | ✅ | `AndroidManifest.xml` — commentaire explicite |
| Pas de URLSession/Alamofire iOS | ✅ | grep 0 résultats (seul un `Link` statique vers policy) |
| Pas de reqwest/socket dans Rust | ✅ | grep 0 résultats |
| Pas de Firebase/Analytics/Amplitude | ✅ | build.gradle.kts grep 0 résultats |
| Pas de télémétrie Swift | ✅ | grep 0 résultats |

### Chiffrement — VÉRIFIÉ
| Check | Status | Détail |
|-------|--------|--------|
| DB chiffrée SQLCipher | ✅ | `bundled-sqlcipher-vendored-openssl` |
| Clé dérivée Argon2id | ✅ | 64MB/3iter/4threads (≈300ms mobile) |
| AES-256-GCM + nonce CSPRNG | ✅ | `vault/crypto.rs` — nonce unique par chiffrement |
| Sous-clés HKDF-SHA256 | ✅ | Clé DB ≠ clé sync — compromission isolée |
| Zeroize sur clés en mémoire | ✅ | `secrecy::SecretVec` + `zeroize` |
| Android Keystore PIN | ✅ | `KeystoreService.kt` — AES-256-GCM hardware-backed |
| iOS Keychain PIN | ✅ | `KeychainService.swift` — `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` |

### Permissions Android utilisées
```
USE_BIOMETRIC, USE_FINGERPRINT          → déverrouillage biométrique
POST_NOTIFICATIONS, SCHEDULE_EXACT_ALARM → rappels locaux uniquement
RECEIVE_BOOT_COMPLETED                  → reprogrammer alarmes après reboot
health.READ/WRITE_MENSTRUATION          → HealthConnect (optionnel)
```

---

## FICHIERS CLÉS

### Rust
```
luna-core/src/
  api.rs              → Interface UniFFI publique (LunaEngine)
  engine/types.rs     → Cycle, DailyLog, Prediction, CycleSummary, symptoms::*
  engine/prediction.rs → PredictionEngine, CyclePhase (calendar|bbt|lh|combined)
  vault/crypto.rs     → derive_key, encrypt, decrypt, generate_salt, secure_zero
  vault/database.rs   → SQLCipher init, PRAGMA key, migrations
  error.rs            → LunaError (8 variants)
  lib.rs              → uniffi::setup_scaffolding!("luna_core")
```

### iOS (SwiftUI)
```
ios-app/
  project.yml                            → xcodegen config (REBUILD si modifié)
  LunaApp/Generated/
    luna_core.swift                      → bindings UniFFI (NE PAS ÉDITER)
    luna_coreFFI.h + luna_coreFFI.modulemap
    module.modulemap                     → copie de luna_coreFFI.modulemap (Xcode)
    libluna_core.a                       → lib statique iOS sim (aarch64-apple-ios-sim)
  LunaApp/Views/
    OnboardingView.swift, LockView.swift, HomeView.swift
    CalendarView.swift, InsightsView.swift, SettingsView.swift
  LunaApp/Resources/Localizable.xcstrings → 97 clés, sourceLanguage="fr", 40 langues
  LunaApp/Services/KeychainService.swift  → ✅ SecItemAdd/CopyMatching/Delete, no iCloud sync
```

### Android (Kotlin Views)
```
android-app/app/src/main/
  generated/uniffi/luna_core/luna_core.kt  → bindings JNA (NE PAS ÉDITER)
  jniLibs/arm64-v8a/libluna_core.so       → ✅ ARM64 (émulateur)
  jniLibs/x86_64/libluna_core.so          → ✅ x86_64
  kotlin/app/luna/
    LunaApplication.kt                     → System.loadLibrary("luna_core")
    services/VaultService.kt               → singleton engine (uniffi.luna_core.LunaEngine)
    services/KeystoreService.kt            → AES-256-GCM Android Keystore ✅
    ui/{LockActivity, OnboardingActivity, MainActivity}.kt
    ui/{LogBottomSheet, SettingsActivity}.kt
    viewmodel/{HomeViewModel, InsightsViewModel}.kt
  res/values/strings.xml                   → 40 langues
  res/drawable/ic_luna_*.xml               → 11 icônes Vector (path-only, transparent fill)
  res/mipmap-anydpi-v26/ic_launcher*.xml   → Adaptive icon (lune croissant)
```

---

## PROBLÈMES CONNUS / TODOs RESTANTS

1. **Parcours utilisateur iOS non déroulé** — onboarding step 1 visible mais flux non testé end-to-end

2. **`LunaApplication.kt` charge la lib au démarrage** — crash si `.so` absent pour l'ABI

3. **`exportEncryptedBackup("")`** dans SettingsActivity — PIN vide, inutilisable en prod

4. **Link statique `https://luna-app.privacy`** dans SettingsView.swift — URL fictive

7. **arm64-v7a non buildé** — seul arm64-v8a et x86_64 présents (suffisant pour prod moderne)

---

## GOTCHAS TECHNIQUES

### UniFFI 0.28 (proc-macros, no .udl)
- Package est une **library**, pas un binary → wrapper `uniffi-bindgen/` requis
- `cargo run -p uniffi-bindgen -- generate --library target/release/libluna_core.dylib ...`
- Kotlin: `com.sun.jna.*` → ajouter `net.java.dev.jna:jna:5.14.0@aar` aux deps
- Xcode: nommer `module.modulemap` (copie de `luna_coreFFI.modulemap`) dans `SWIFT_INCLUDE_PATHS`

### iOS onChange compat iOS 16
- `onChange(of: x) { _, new in }` → iOS 17+ seulement
- iOS 16 : `onChange(of: x) { new in }` (un seul paramètre)

### Android Material3 1.12.0 gotchas
- `android:colorBackground` uniquement (pas sans préfixe)
- `itemActiveIndicatorColor` n'existe pas dans cette version
- `PreferenceThemeOverlay.Material3` n'existe pas
- `android:fillColor="none"` invalide → `"@android:color/transparent"`

### SQLCipher cross-compilation Android
- `bundled-sqlcipher-vendored-openssl` requis (OpenSSL vendorisé)
- NDK 27.2 sur Apple Silicon → toolchain `darwin-x86_64` via Rosetta 2

### Émulateur Android
- Démarrer avec `nohup ... > /tmp/emu.log 2>&1 &` pour persistance
- GPU : `-gpu swiftshader_indirect` obligatoire (Vulkan via SwiftShader)
- Attendre ~60s avant `adb devices` après `nohup`

---

## ACCEPTANCE CRITERIA — ÉTAT

| Critère | Statut |
|---------|--------|
| Zéro permission réseau | ✅ |
| DB chiffrée AES-256 | ✅ |
| PIN → Argon2id + SQLCipher | ✅ |
| Android Keystore PIN | ✅ |
| iOS Keychain PIN | ✅ |
| Panic wipe | ✅ Rust `panic_wipe()` |
| Export backup chiffré | ✅ API Rust (UI partielle) |
| iOS build sur simulateur | ✅ iPhone 16 Pro (Xcode 26) |
| Android build sur émulateur | ✅ Pixel6_API34 ARM64 |
| Rust 23 tests | ✅ |
| i18n 40 langues | ✅ xcstrings + strings.xml |
| WCAG 2.2 AA | ✅ contentDescription, a11yLabel, RTL |
| Parcours utilisateur déroulé | ⚠️ Partiel (onboarding visible, flow non validé) |

---

## COMMANDES RAPIDES

```bash
# Tests Rust
cd _FLO && cargo test

# Screenshot iOS sim
xcrun simctl io booted screenshot /tmp/luna_ios.png

# Screenshot Android emu
adb -s emulator-5554 shell screencap -p /sdcard/s.png && adb -s emulator-5554 pull /sdcard/s.png /tmp/luna_android.png

# Rebuild complet iOS
cd _FLO && \
  cargo build --release --target aarch64-apple-ios-sim && \
  cp target/aarch64-apple-ios-sim/release/libluna_core.a ios-app/LunaApp/Generated/ && \
  cd ios-app && xcodegen generate

# Rebuild complet Android
cd _FLO && \
  ANDROID_NDK_HOME=~/Library/Android/sdk/ndk/27.2.12479018 \
  cargo ndk --target arm64-v8a --output-dir android-app/app/src/main/jniLibs -- build --release && \
  cd android-app && ./gradlew assembleDebug

# Logcat crash Android
adb -s emulator-5554 shell logcat -d | grep -E "FATAL|AndroidRuntime|app.luna"
```

---

## DESIGN SYSTEM

- Tokens: `luna-design-system/tokens/` (colors, spacing, typography, shadows)
- Couleurs primaires: `plum-600 = #7C3AED`, `coral-500 = #F87171`, `sage-400 = #6EE7B7`
- Dark mode: fond `#0D0D14` (near-black), surface `#1A1A2E`
- Icons: Feather SVG set (42 icônes, 24px stroke-only)
- Cultural: couleur rouge menstruel désactivable (cultures où rouge = tabou)
- RTL: support complet arabe/hébreu/persan/ourdou

---

*Dernière mise à jour: 2026-03-05 — iOS ✅ Android ✅ Rust ✅ 23 tests*
