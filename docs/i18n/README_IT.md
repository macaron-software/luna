<div align="center">

# LUNA — Italiano

**Il tuo ciclo. Il tuo telefono. Nessun server. Nessun cloud. Zero compromessi.**

[![No server](https://img.shields.io/badge/server-none-brightgreen.svg)](#)
[![Offline](https://img.shields.io/badge/works-100%25%20offline-brightgreen.svg)](#)
[![License](https://img.shields.io/badge/license-MIT%20%2F%20Apache--2.0-blue.svg)](../../README.md)

</div>

[← English (full docs)](../../README.md)

---

## Promessa sulla privacy

| | |
|---|---|
| 📵 | **Nessun server.** Non ne abbiamo. Nessun backend, nessun database remoto, nessun endpoint API a cui l'app si connette. |
| 📶 | **Funziona al 100% offline.** Nessuna connessione internet è mai richiesta o utilizzata. Installa una volta, usa per sempre senza rete. |
| 🚷 | **Nessun account, nessuna registrazione.** Nessuna email, nessuna password, nessun login social, nessuna verifica d'identità. Nulla. |
| 🧩 | **Nessuna dipendenza da servizi di terze parti.** Nessun Firebase, Google Analytics, Mixpanel, Sentry, Amplitude. Zero SDK esterni. |
| 🔐 | **Dati cifrati solo sul tuo telefono.** Database SQLCipher cifrato con AES-256-GCM. Chiave derivata dal tuo PIN via Argon2id. La chiave non lascia mai il dispositivo. |
| ☁️ | **Backup cloud opzionale — completamente cifrato.** iCloud/Google Drive riceve un blob cifrato opaco. Nemmeno Apple e Google possono leggerlo. |
| 🚫 | **Zero telemetria, zero analytics.** Nessun report di crash, nessuna metrica di utilizzo, nessun A/B test. Niente lascia il tuo telefono. |
| 💥 | **Cancellazione di emergenza in 3 secondi.** Tieni premuto il pulsante: database + salt + tutte le chiavi crittografiche vengono distrutte irreversibilmente. |
| 🔓 | **100% open source.** MIT/Apache-2.0. Ogni riga di codice è pubblica e verificabile da chiunque. |

---

## Cosa LUNA non farà MAI

| | |
|---|---|
| **Nessun server** | Non ne abbiamo. Impossibile inviare i tuoi dati da qualsiasi parte. |
| **Senza internet** | L'app funziona al 100% offline. Sempre. |
| **Senza account** | Senza email, senza password, senza login. |
| **Senza vendita di dati** | Impossibile — non li riceviamo mai. |
| **Senza pubblicità** | Zero SDK pubblicitari, zero pixel di tracciamento. |
| **Senza telemetria push** | I promemoria usano solo il sistema OS — nessun dato via server. |
| **Senza SDK nascosti** | Il binario contiene solo ciò che vedi in questo repository. |

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

## Architettura

```
Core Rust condiviso (UniFFI) · SwiftUI iOS · Kotlin Android · SQLCipher cifrato · zero rete
```

---

## License

MIT / Apache-2.0 — [LICENSE](../../README.md)

> ⚠️ Questa app non fornisce consulenza medica.
