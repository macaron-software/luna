<div align="center">

# LUNA — Hrvatski

**Vaš ciklus. Vaš telefon. Bez poslužitelja. Bez oblaka. Nula kompromisa.**

[![No server](https://img.shields.io/badge/server-none-brightgreen.svg)](#)
[![Offline](https://img.shields.io/badge/works-100%25%20offline-brightgreen.svg)](#)
[![License](https://img.shields.io/badge/license-MIT%20%2F%20Apache--2.0-blue.svg)](../../README.md)

</div>

[← English (full docs)](../../README.md)

---

## Privacy Pledge

| | |
|---|---|
| 📵 | **No server.** We do not have one. No backend, no remote database, no API endpoint the app ever calls. |
| 📶 | **Works 100% offline.** No internet connection is ever required or used. Install once, use forever without a network. |
| 🚷 | **No account, no registration.** No email, no password, no social login, no identity verification. Nothing. |
| 🧩 | **No third-party service dependency.** No Firebase, no Google Analytics, no Mixpanel, no Sentry, no Amplitude. Zero external SDKs. |
| 🔐 | **Data encrypted on your phone only.** AES-256-GCM encrypted SQLCipher database. Key derived from your PIN via Argon2id. The key never leaves the device. |
| ☁️ | **Optional encrypted backup.** iCloud/Google Drive receives an opaque ciphertext blob. Even Apple and Google cannot read it. |
| 🚫 | **Zero telemetry, zero analytics.** No crash reports, no usage metrics, no A/B tests. Nothing leaves your phone. |
| 💥 | **Panic wipe in 3 seconds.** Hold the button: database + salt + all cryptographic keys destroyed irreversibly. |
| 🔓 | **100% open source.** MIT/Apache-2.0. Every line of code is public and auditable by anyone. |

---

## Što LUNA NIKADA neće učiniti

| | |
|---|---|
| **No server** | We don't have one. Impossible to send your data anywhere. |
| **No internet required** | The app works 100% offline. Always. |
| **No account** | No email, no password, no login. |
| **No data sale** | Impossible — we never receive it. |
| **No ads** | Zero advertising SDK, zero tracking pixel. |
| **No push telemetry** | Reminders use OS system only — no data via any server. |
| **No hidden SDK** | The binary contains only what you see in this repository. |

```
iOS:     ATS enforced — no arbitrary network loads
Android: networkSecurityConfig blocks ALL outbound connections
Rust:    Cargo.toml has zero networking dependencies
```

---

## Screenshots

| Home | Log | Calendar | Insights | Security |
|------|-----|----------|----------|---------|
| ![](../../docs/screenshots/01_home_en.png) | ![](../../docs/screenshots/02_log_en.png) | ![](../../docs/screenshots/03_calendar_en.png) | ![](../../docs/screenshots/04_insights_en.png) | ![](../../docs/screenshots/05_security_en.png) |

---

## Arhitektura

```
Zajednička Rust jezgra (UniFFI) · SwiftUI iOS · Kotlin Android · SQLCipher šifrirano · nula mreža
```

---

## License

MIT / Apache-2.0 — [LICENSE](../../README.md)

> ⚠️ This app does not provide medical advice.
