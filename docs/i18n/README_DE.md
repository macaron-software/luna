<div align="center">

# LUNA — Deutsch

**Ihr Zyklus. Ihr Telefon. Kein Server. Keine Cloud. Kein Kompromiss.**

[![No server](https://img.shields.io/badge/server-none-brightgreen.svg)](#)
[![Offline](https://img.shields.io/badge/works-100%25%20offline-brightgreen.svg)](#)
[![License](https://img.shields.io/badge/license-MIT%20%2F%20Apache--2.0-blue.svg)](../../README.md)

</div>

[← English (full docs)](../../README.md)

---

## Datenschutzversprechen

| | |
|---|---|
| 📵 | **Kein Server.** Wir haben keinen. Kein Backend, keine Remote-Datenbank, kein API-Endpunkt, den die App aufruft. |
| 📶 | **Funktioniert 100 % offline.** Es wird nie eine Internetverbindung benötigt oder genutzt. Einmal installieren, ewig ohne Netz nutzen. |
| 🚷 | **Kein Konto, keine Registrierung.** Keine E-Mail, kein Passwort, kein Social-Login, keine Identitätsprüfung. Nichts. |
| 🧩 | **Keine Abhängigkeit von Drittanbieterdiensten.** Kein Firebase, kein Google Analytics, kein Mixpanel, kein Sentry, kein Amplitude. Null externe SDKs. |
| 🔐 | **Verschlüsselte Daten nur auf Ihrem Telefon.** SQLCipher-Datenbank mit AES-256-GCM. Schlüssel via Argon2id aus Ihrer PIN. Der Schlüssel verlässt das Gerät nie. |
| ☁️ | **Optionales Cloud-Backup — vollständig verschlüsselt.** iCloud/Google Drive empfängt ein opakes verschlüsseltes Blob. Selbst Apple und Google können es nicht lesen. |
| 🚫 | **Null Telemetrie, null Analytics.** Keine Crash-Berichte, keine Nutzungsmetriken, kein A/B-Testing. Nichts verlässt Ihr Telefon. |
| 💥 | **Panik-Wipe in 3 Sekunden.** Taste gedrückt halten: Datenbank + Salt + alle Schlüssel werden unwiderruflich gelöscht. |
| 🔓 | **100 % Open Source.** MIT/Apache-2.0. Jede Codezeile ist öffentlich und für jeden auditierbar. |

---

## Was LUNA NIEMALS tun wird

| | |
|---|---|
| **Kein Server** | Wir haben keinen. Unmöglich, Ihre Daten irgendwohin zu senden. |
| **Kein Internet nötig** | Die App funktioniert 100 % offline. Immer. |
| **Kein Konto** | Keine E-Mail, kein Passwort, keine Anmeldung. |
| **Kein Datenverkauf** | Unmöglich — wir empfangen sie nie. |
| **Keine Werbung** | Null Werbe-SDK, null Tracking-Pixel. |
| **Keine Push-Telemetrie** | Erinnerungen nutzen nur das OS-System — keine Daten über Server. |
| **Kein verstecktes SDK** | Das Binary enthält nur, was Sie in diesem Repository sehen. |

```
iOS:     ATS enforced — no arbitrary network loads
Android: networkSecurityConfig blocks ALL outbound connections
Rust:    Cargo.toml has zero networking dependencies
```

---

## Screenshots

| Home | Log | Calendar | Insights | Security |
|------|-----|----------|----------|---------|
| ![](../../docs/screenshots/01_home_de.png) | ![](../../docs/screenshots/02_log_de.png) | ![](../../docs/screenshots/03_calendar_de.png) | ![](../../docs/screenshots/04_insights_en.png) | ![](../../docs/screenshots/05_security_en.png) |

---

## Architektur

```
Gemeinsamer Rust-Kern (UniFFI) · SwiftUI iOS · Kotlin Android · SQLCipher verschlüsselt · kein Netzwerk
```

---

## License

MIT / Apache-2.0 — [LICENSE](../../README.md)

> ⚠️ Diese App bietet keine medizinische Beratung.
