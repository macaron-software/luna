<div align="center">

# LUNA — Português BR

**Seu ciclo. Seu telefone. Nenhum servidor. Nenhuma nuvem. Zero compromisso.**

[![No server](https://img.shields.io/badge/server-none-brightgreen.svg)](#)
[![Offline](https://img.shields.io/badge/works-100%25%20offline-brightgreen.svg)](#)
[![License](https://img.shields.io/badge/license-MIT%20%2F%20Apache--2.0-blue.svg)](../../README.md)

</div>

[← English (full docs)](../../README.md)

---

## Compromisso de privacidade

| | |
|---|---|
| 📵 | **Nenhum servidor.** Não temos nenhum. Sem backend, sem banco de dados remoto, nenhum endpoint de API que o app usa. |
| 📶 | **Funciona 100% offline.** Nenhuma conexão com a internet é jamais necessária ou usada. Instale uma vez, use para sempre sem rede. |
| 🚷 | **Sem conta, sem cadastro.** Sem e-mail, sem senha, sem login social, sem verificação de identidade. Nada. |
| 🧩 | **Sem dependência de serviços de terceiros.** Sem Firebase, sem Google Analytics, sem Mixpanel, sem Sentry, sem Amplitude. Zero SDKs externos. |
| 🔐 | **Dados criptografados apenas no seu telefone.** Banco de dados SQLCipher criptografado com AES-256-GCM. Chave derivada do seu PIN via Argon2id. A chave nunca sai do dispositivo. |
| ☁️ | **Backup em nuvem opcional — totalmente criptografado.** iCloud/Google Drive recebe um blob criptografado opaco. Nem Apple nem Google conseguem lê-lo. |
| 🚫 | **Zero telemetria, zero analytics.** Sem relatórios de falha, sem métricas de uso, sem testes A/B. Nada sai do seu telefone. |
| 💥 | **Apagamento de pânico em 3 segundos.** Segure o botão: banco de dados + sal + todas as chaves criptográficas são destruídas irreversivelmente. |
| 🔓 | **100% código aberto.** MIT/Apache-2.0. Cada linha de código é pública e auditável por qualquer pessoa. |

---

## O que a LUNA NUNCA fará

| | |
|---|---|
| **Nenhum servidor** | Não temos. Impossível enviar seus dados para qualquer lugar. |
| **Sem internet necessária** | O app funciona 100% offline. Sempre. |
| **Sem conta** | Sem e-mail, sem senha, sem login. |
| **Sem venda de dados** | Impossível — nunca os recebemos. |
| **Sem anúncios** | Zero SDK de publicidade, zero pixel de rastreamento. |
| **Sem telemetria push** | Lembretes usam apenas o sistema OS — sem dados por servidor. |
| **Sem SDK oculto** | O binário contém apenas o que você vê neste repositório. |

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

## Arquitetura

```
Núcleo Rust compartilhado (UniFFI) · SwiftUI iOS · Kotlin Android · SQLCipher criptografado · zero rede
```

---

## License

MIT / Apache-2.0 — [LICENSE](../../README.md)

> ⚠️ Este aplicativo não fornece conselho médico.
