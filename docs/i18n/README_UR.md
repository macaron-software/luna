<div align="center">

# LUNA — اردو

**آپ کا سائیکل۔ آپ کا فون۔ کوئی سرور نہیں۔ کوئی کلاؤڈ نہیں۔ صفر سمجھوتہ۔**

[![No server](https://img.shields.io/badge/server-none-brightgreen.svg)](#)
[![Offline](https://img.shields.io/badge/works-100%25%20offline-brightgreen.svg)](#)
[![License](https://img.shields.io/badge/license-MIT%20%2F%20Apache--2.0-blue.svg)](../../README.md)

</div>

[← English (full docs)](../../README.md)

---

## رازداری کا وعدہ

| | |
|---|---|
| 📵 | **کوئی سرور نہیں۔** ہمارے پاس کوئی نہیں ہے۔ کوئی backend نہیں، کوئی remote database نہیں، کوئی API endpoint نہیں جس سے ایپ جڑتی ہو۔ |
| 📶 | **100% آف لائن کام کرتا ہے۔** انٹرنیٹ کنکشن کبھی ضروری نہیں اور نہ استعمال ہوتا ہے۔ ایک بار انسٹال کریں، نیٹ ورک کے بغیر ہمیشہ کے لیے استعمال کریں۔ |
| 🚷 | **کوئی اکاؤنٹ نہیں، کوئی رجسٹریشن نہیں۔** کوئی ای میل نہیں، کوئی پاس ورڈ نہیں، کوئی سوشل لاگ ان نہیں۔ کچھ بھی نہیں۔ |
| 🧩 | **کسی تھرڈ پارٹی سروس پر انحصار نہیں۔** کوئی Firebase، Google Analytics، Mixpanel، Sentry نہیں۔ صفر بیرونی SDK۔ |
| 🔐 | **ڈیٹا صرف آپ کے فون پر انکرپٹ ہے۔** AES-256-GCM انکرپٹڈ SQLCipher database۔ PIN کے ذریعے Argon2id سے حاصل کردہ چابی۔ چابی کبھی ڈیوائس نہیں چھوڑتی۔ |
| ☁️ | **اختیاری کلاؤڈ بیک اپ — مکمل طور پر انکرپٹڈ۔** iCloud/Google Drive کو صرف ایک مبہم انکرپٹڈ blob ملتا ہے۔ Apple اور Google بھی اسے نہیں پڑھ سکتے۔ |
| 🚫 | **صفر telemetry، صفر analytics۔** کوئی crash report نہیں، کوئی usage metrics نہیں، کوئی A/B testing نہیں۔ کچھ بھی آپ کا فون نہیں چھوڑتا۔ |
| 💥 | **3 سیکنڈ میں panic wipe۔** بٹن دبائے رکھیں: database + salt + تمام cryptographic چابیاں ناقابل واپسی طور پر تباہ ہو جاتی ہیں۔ |
| 🔓 | **100% اوپن سورس۔** MIT/Apache-2.0۔ کوڈ کی ہر لائن عوامی ہے اور کوئی بھی آڈٹ کر سکتا ہے۔ |

---

## LUNA کبھی کیا نہیں کرے گا

| | |
|---|---|
| **کوئی سرور نہیں** | ہمارے پاس نہیں ہے۔ آپ کا ڈیٹا کہیں بھیجنا ناممکن ہے۔ |
| **انٹرنیٹ کی ضرورت نہیں** | ایپ 100% آف لائن کام کرتی ہے۔ ہمیشہ۔ |
| **کوئی اکاؤنٹ نہیں** | کوئی ای میل نہیں، کوئی پاس ورڈ نہیں، کوئی لاگ ان نہیں۔ |
| **ڈیٹا کی فروخت نہیں** | ناممکن — ہم اسے کبھی حاصل نہیں کرتے۔ |
| **کوئی اشتہارات نہیں** | صفر اشتہار SDK، صفر tracking pixel۔ |
| **push telemetry نہیں** | یاد دہانیاں صرف OS system استعمال کرتی ہیں — سرور کے ذریعے کوئی ڈیٹا نہیں۔ |
| **کوئی چھپا SDK نہیں** | binary میں صرف وہی ہے جو آپ اس repository میں دیکھتے ہیں۔ |

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

## فن تعمیر

```
مشترک Rust core (UniFFI) · SwiftUI iOS · Kotlin Android · SQLCipher انکرپشن · صفر نیٹ ورک
```

---

## License

MIT / Apache-2.0 — [LICENSE](../../README.md)

> ⚠️ یہ ایپ طبی مشورہ نہیں دیتی۔
