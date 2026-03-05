<div align="center">

# LUNA — Español

**Tu ciclo. Tu teléfono. Ningún servidor. Ninguna nube. Cero compromisos.**

[![No server](https://img.shields.io/badge/server-none-brightgreen.svg)](#)
[![Offline](https://img.shields.io/badge/works-100%25%20offline-brightgreen.svg)](#)
[![License](https://img.shields.io/badge/license-MIT%20%2F%20Apache--2.0-blue.svg)](../../README.md)

</div>

[← English (full docs)](../../README.md)

---

## Promesa de privacidad

| | |
|---|---|
| 📵 | **Ningún servidor.** No tenemos ninguno. Sin backend, sin base de datos remota, sin punto de API al que la app se conecte. |
| 📶 | **Funciona 100% sin conexión.** Nunca se requiere ni se usa conexión a internet. Instala una vez, usa siempre sin red. |
| 🚷 | **Sin cuenta, sin registro.** Sin email, sin contraseña, sin login social, sin verificación de identidad. Nada. |
| 🧩 | **Sin dependencia de servicios de terceros.** Sin Firebase, sin Google Analytics, sin Mixpanel, sin Sentry, sin Amplitude. Cero SDKs externos. |
| 🔐 | **Datos cifrados solo en tu teléfono.** Base de datos SQLCipher cifrada con AES-256-GCM. Clave derivada de tu PIN via Argon2id. La clave nunca sale del dispositivo. |
| ☁️ | **Copia de seguridad cloud opcional — completamente cifrada.** iCloud/Google Drive recibe un blob cifrado opaco. Ni Apple ni Google pueden leerlo. |
| 🚫 | **Cero telemetría, cero analítica.** Sin informes de fallos, sin métricas de uso, sin pruebas A/B. Nada sale de tu teléfono. |
| 💥 | **Borrado de pánico en 3 segundos.** Mantén el botón: base de datos + sal + todas las claves criptográficas se destruyen irreversiblemente. |
| 🔓 | **100% código abierto.** MIT/Apache-2.0. Cada línea de código es pública y auditable por cualquiera. |

---

## Lo que LUNA NUNCA hará

| | |
|---|---|
| **Sin servidor** | No tenemos ninguno. Imposible enviar tus datos a ningún lado. |
| **Sin internet requerido** | La app funciona 100% offline. Siempre. |
| **Sin cuenta** | Sin email, sin contraseña, sin login. |
| **Sin venta de datos** | Imposible — nunca los recibimos. |
| **Sin publicidad** | Cero SDK publicitario, cero píxel de seguimiento. |
| **Sin telemetría push** | Los recordatorios usan solo el sistema OS — sin datos por servidor. |
| **Sin SDK oculto** | El binario contiene solo lo que ves en este repositorio. |

```
iOS:     ATS enforced — no arbitrary network loads
Android: networkSecurityConfig blocks ALL outbound connections
Rust:    Cargo.toml has zero networking dependencies
```

---

## Screenshots

| Home | Log | Calendar | Insights | Security |
|------|-----|----------|----------|---------|
| ![](../../docs/screenshots/01_home_es.png) | ![](../../docs/screenshots/02_log_es.png) | ![](../../docs/screenshots/03_calendar_es.png) | ![](../../docs/screenshots/04_insights_en.png) | ![](../../docs/screenshots/05_security_en.png) |

---

## Arquitectura

```
Núcleo Rust compartido (UniFFI) · SwiftUI iOS · Kotlin Android · SQLCipher cifrado · cero red
```

---

## License

MIT / Apache-2.0 — [LICENSE](../../README.md)

> ⚠️ Esta aplicación no ofrece consejo médico.
