<div align="center">

# LUNA — Nederlands

**Jouw cyclus. Jouw telefoon. Geen server. Geen cloud. Nul compromissen.**

[![No server](https://img.shields.io/badge/server-none-brightgreen.svg)](#)
[![Offline](https://img.shields.io/badge/works-100%25%20offline-brightgreen.svg)](#)
[![License](https://img.shields.io/badge/license-MIT%20%2F%20Apache--2.0-blue.svg)](../../README.md)

</div>

[← English (full docs)](../../README.md)

---

## Privacybelofte

| | |
|---|---|
| 📵 | **Geen server.** Wij hebben er geen. Geen backend, geen externe database, geen API-eindpunt waarmee de app verbinding maakt. |
| 📶 | **Werkt 100% offline.** Er is nooit een internetverbinding nodig of wordt gebruikt. Eenmalig installeren, altijd gebruiken zonder netwerk. |
| 🚷 | **Geen account, geen registratie.** Geen e-mail, geen wachtwoord, geen sociale login, geen identiteitsverificatie. Niets. |
| 🧩 | **Geen afhankelijkheid van diensten van derden.** Geen Firebase, Google Analytics, Mixpanel, Sentry, Amplitude. Nul externe SDK's. |
| 🔐 | **Gegevens alleen versleuteld op jouw telefoon.** SQLCipher-database versleuteld met AES-256-GCM. Sleutel afgeleid van jouw PIN via Argon2id. De sleutel verlaat het apparaat nooit. |
| ☁️ | **Optionele cloudback-up — volledig versleuteld.** iCloud/Google Drive ontvangt een ondoorzichtige versleutelde blob. Zelfs Apple en Google kunnen het niet lezen. |
| 🚫 | **Nul telemetrie, nul analytics.** Geen crashrapporten, geen gebruiksstatistieken, geen A/B-tests. Niets verlaat jouw telefoon. |
| 💥 | **Paniekvegwissen in 3 seconden.** Houd de knop ingedrukt: database + salt + alle cryptografische sleutels worden onomkeerbaar vernietigd. |
| 🔓 | **100% open source.** MIT/Apache-2.0. Elke regel code is openbaar en door iedereen te auditen. |

---

## Wat LUNA NOOIT zal doen

| | |
|---|---|
| **Geen server** | Wij hebben er geen. Onmogelijk om jouw gegevens ergens naartoe te sturen. |
| **Geen internet nodig** | De app werkt 100% offline. Altijd. |
| **Geen account** | Geen e-mail, geen wachtwoord, geen login. |
| **Geen dataverkoop** | Onmogelijk — we ontvangen het nooit. |
| **Geen advertenties** | Nul advertentie-SDK, nul trackingpixels. |
| **Geen push-telemetrie** | Herinneringen gebruiken alleen het OS-systeem — geen gegevens via server. |
| **Geen verborgen SDK** | Het binaire bestand bevat alleen wat je in deze repository ziet. |

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

## Architectuur

```
Gedeelde Rust-kern (UniFFI) · SwiftUI iOS · Kotlin Android · SQLCipher versleuteld · nul netwerk
```

---

## License

MIT / Apache-2.0 — [LICENSE](../../README.md)

> ⚠️ Deze app biedt geen medisch advies.
