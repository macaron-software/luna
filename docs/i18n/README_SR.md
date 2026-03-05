<div align="center">

# LUNA

**Праћење менструалног циклуса уз поштовање приватности — нула сервера, нула облака, нула компромиса.**

[![iOS](https://img.shields.io/badge/iOS-16%2B-lightblue.svg)](../../ios-app/)
[![Android](https://img.shields.io/badge/Android-API%2023%2B-green.svg)](../../android-app/)
[![License](https://img.shields.io/badge/license-MIT%20%2F%20Apache--2.0-blue.svg)](../../LICENSE-MIT)

[← README](../../README.md)

</div>

---

## Privacy / Datenschutz / Privacidad / Confidentialité

| | |
|---|---|
| Zero server | No account · No registration · No external dependency · 100% offline |
| AES-256-GCM | Argon2id key derivation · HKDF-SHA256 subkeys · Keys zeroized on drop |
| Local storage | All data on your device · SQLCipher encrypted database |
| Encrypted backup | iCloud/Google Drive blob — opaque ciphertext even to Apple/Google |
| Zero sharing | No analytics · No telemetry · No ads SDK · No crash reporting |
| Open source | MIT/Apache-2.0 · Every line auditable |
| Panic wipe | Destroys vault + keys in < 500ms |
| Science | Evidence-based predictions · Weighted moving average · No pseudoscience |

---

## Architecture

```
luna-core/     Rust — UniFFI 0.28 — AES-256-GCM + Argon2id + SQLCipher
ios-app/       SwiftUI iOS 16+ — Keychain — HealthKit (optional)
android-app/   Kotlin API 23+ — Keystore — HealthConnect (optional)
```

**41 tests** (Rust behavior + crypto + prediction + CSV + iOS + Android)

---

## Language: Српски

> Праћење менструалног циклуса уз поштовање приватности — нула сервера, нула облака, нула компромиса.

---

## Build

```bash
cargo test -p luna-core              # 41 Rust tests
cd ios-app && xcodebuild build       # iOS (Xcode 15+)
cd android-app && ./gradlew assembleDebug  # Android
```

---

## i18n — 40 languages supported

RTL: Arabic · Hebrew · Persian (full layout mirror)
WCAG 2.2 AA · Calm Mode (psy accessibility) · Reduce Motion

---

## License

MIT / Apache-2.0 — Copyright © 2026 LUNA contributors

> This app does not provide medical advice. Consult a healthcare professional for medical concerns.
