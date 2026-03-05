<div align="center">

# LUNA — 简体中文

**您的周期。您的手机。无服务器。无云端。零妥协。**

[![No server](https://img.shields.io/badge/server-none-brightgreen.svg)](#)
[![Offline](https://img.shields.io/badge/works-100%25%20offline-brightgreen.svg)](#)
[![License](https://img.shields.io/badge/license-MIT%20%2F%20Apache--2.0-blue.svg)](../../README.md)

</div>

[← English (full docs)](../../README.md)

---

## 隐私承诺

| | |
|---|---|
| 📵 | **无服务器。** 我们没有服务器。无后端，无远程数据库，无应用连接的API端点。 |
| 📶 | **100% 离线运行。** 从不需要或使用互联网连接。安装一次，无需网络永久使用。 |
| 🚷 | **无账户，无注册。** 无电子邮件，无密码，无社交登录，无身份验证。什么都不需要。 |
| 🧩 | **不依赖任何第三方服务。** 无Firebase，无Google Analytics，无Mixpanel，无Sentry，无Amplitude。零外部SDK。 |
| 🔐 | **数据仅加密存储在您的手机上。** AES-256-GCM加密的SQLCipher数据库。通过Argon2id从PIN派生密钥。密钥永不离开设备。 |
| ☁️ | **可选云备份——完全加密。** iCloud/Google Drive收到不透明的加密数据块。即使Apple和Google也无法读取。 |
| 🚫 | **零遥测，零分析。** 无崩溃报告，无使用指标，无A/B测试。没有任何东西离开您的手机。 |
| 💥 | **3秒紧急清除。** 长按按钮：数据库+盐+所有加密密钥不可逆地销毁。 |
| 🔓 | **100% 开源。** MIT/Apache-2.0。每一行代码都是公开的，任何人都可以审计。 |

---

## LUNA绝对不会做的事

| | |
|---|---|
| **无服务器** | 我们没有。不可能把您的数据发送到任何地方。 |
| **无需互联网** | 应用100% 离线运行。始终如此。 |
| **无账户** | 无邮件，无密码，无登录。 |
| **不出售数据** | 不可能——我们从不接收数据。 |
| **无广告** | 零广告SDK，零追踪像素。 |
| **无Push遥测** | 提醒仅使用OS系统——无数据通过服务器。 |
| **无隐藏SDK** | 二进制文件只包含您在此仓库中看到的内容。 |

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

## 架构

```
共享Rust核心 (UniFFI) · SwiftUI iOS · Kotlin Android · SQLCipher加密 · 零网络
```

---

## License

MIT / Apache-2.0 — [LICENSE](../../README.md)

> ⚠️ 本应用不提供医疗建议。
