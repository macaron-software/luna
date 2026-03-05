<div align="center">

# LUNA — 繁體中文

**您的週期。您的手機。無伺服器。無雲端。零妥協。**

[![No server](https://img.shields.io/badge/server-none-brightgreen.svg)](#)
[![Offline](https://img.shields.io/badge/works-100%25%20offline-brightgreen.svg)](#)
[![License](https://img.shields.io/badge/license-MIT%20%2F%20Apache--2.0-blue.svg)](../../README.md)

</div>

[← English (full docs)](../../README.md)

---

## 隱私承諾

| | |
|---|---|
| 📵 | **無伺服器。** 我們沒有伺服器。無後端，無遠端資料庫，無應用程式連接的API端點。 |
| 📶 | **100% 離線運作。** 從不需要或使用網路連線。安裝一次，無需網路永久使用。 |
| 🚷 | **無帳戶，無註冊。** 無電子郵件，無密碼，無社交登入，無身份驗證。什麼都不需要。 |
| 🧩 | **不依賴任何第三方服務。** 無Firebase，無Google Analytics，無Mixpanel，無Sentry。零外部SDK。 |
| 🔐 | **資料僅加密存儲在您的手機上。** AES-256-GCM加密的SQLCipher資料庫。密鑰永不離開裝置。 |
| ☁️ | **可選雲端備份——完全加密。** iCloud/Google Drive收到不透明的加密數據塊。即使Apple和Google也無法讀取。 |
| 🚫 | **零遙測，零分析。** 沒有任何東西離開您的手機。 |
| 💥 | **3秒緊急清除。** 長按按鈕：資料庫+鹽+所有加密密鑰不可逆地銷毀。 |
| 🔓 | **100% 開源。** MIT/Apache-2.0。每一行程式碼都是公開的，任何人都可以審計。 |

---

## LUNA絕對不會做的事

| | |
|---|---|
| **無伺服器** | 我們沒有。不可能把您的數據發送到任何地方。 |
| **無需網路** | 應用100% 離線運作。 |
| **無帳戶** | 無郵件，無密碼，無登入。 |
| **不出售數據** | 不可能——我們從不接收數據。 |
| **無廣告** | 零廣告SDK，零追蹤像素。 |
| **無Push遙測** | 提醒僅使用OS系統。 |
| **無隱藏SDK** | 二進位檔案只包含您在此儲存庫中看到的內容。 |

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

## 架構

```
共享Rust核心 (UniFFI) · SwiftUI iOS · Kotlin Android · SQLCipher加密 · 零網路
```

---

## License

MIT / Apache-2.0 — [LICENSE](../../README.md)

> ⚠️ 本應用程式不提供醫療建議。
