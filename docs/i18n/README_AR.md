<div align="center" dir="rtl">

# LUNA — العربية

**دورتك. هاتفك. لا خادم. لا سحابة. لا تنازلات.**

[![No server](https://img.shields.io/badge/server-none-brightgreen.svg)](#)
[![Offline](https://img.shields.io/badge/works-100%25%20offline-brightgreen.svg)](#)
[![License](https://img.shields.io/badge/license-MIT%20%2F%20Apache--2.0-blue.svg)](../../README.md)

</div>

[← English (full docs)](../../README.md)

---

## التزام الخصوصية

| | |
|---|---|
| 📵 | **لا خادم على الإطلاق.** ليس لدينا خادم. لا backend، لا قاعدة بيانات بعيدة، لا نقطة API تتصل بها التطبيقة. |
| 📶 | **يعمل 100% بدون إنترنت.** لا يُستخدم اتصال بالإنترنت أبدًا ولا يُطلب. ثبّت مرة واحدة، استخدم للأبد بدون شبكة. |
| 🚷 | **لا حساب، لا تسجيل.** لا بريد إلكتروني، لا كلمة مرور، لا تسجيل دخول اجتماعي، لا التحقق من الهوية. لا شيء. |
| 🧩 | **لا اعتماد على خدمات طرف ثالث.** لا Firebase، لا Google Analytics، لا Mixpanel، لا Sentry، لا Amplitude. صفر SDK خارجي. |
| 🔐 | **البيانات مشفرة على هاتفك فقط.** قاعدة بيانات SQLCipher مشفرة بـ AES-256-GCM. المفتاح مشتق من رمز PIN عبر Argon2id. لا يغادر المفتاح الجهاز أبدًا. |
| ☁️ | **نسخ احتياطي اختياري في السحابة — مشفر تمامًا.** iCloud/Google Drive يستقبل كتلة مشفرة غير شفافة. حتى Apple وGoogle لا يستطيعان قراءتها. |
| 🚫 | **صفر قياس أداء، صفر تحليلات.** لا تقارير أعطال، لا مقاييس استخدام، لا اختبارات A/B. لا شيء يغادر هاتفك. |
| 💥 | **محو الذعر في 3 ثوانٍ.** اضغط مطولًا على الزر: قاعدة البيانات + الملح + جميع المفاتيح التشفيرية تُتلف بشكل لا رجعة فيه. |
| 🔓 | **100% مفتوح المصدر.** MIT/Apache-2.0. كل سطر كود علني وقابل للمراجعة من قبل أي شخص. |

---

## ما لن تفعله LUNA أبدًا

| | |
|---|---|
| **لا خادم** | ليس لدينا. مستحيل إرسال بياناتك إلى أي مكان. |
| **لا إنترنت مطلوب** | التطبيق يعمل 100% بدون شبكة. دائمًا. |
| **لا حساب** | لا بريد، لا كلمة مرور، لا تسجيل دخول. |
| **لا بيع للبيانات** | مستحيل — لا نستقبلها أبدًا. |
| **لا إعلانات** | صفر SDK إعلاني، صفر بكسل تتبع. |
| **لا قياس Push** | التذكيرات تستخدم نظام OS فقط — بدون بيانات عبر أي خادم. |
| **لا SDK مخفي** | البرنامج الثنائي يحتوي فقط على ما تراه في هذا المستودع. |

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

## البنية التقنية

```
نواة Rust مشتركة (UniFFI) · SwiftUI iOS · Kotlin Android · SQLCipher مشفّر · صفر شبكة
```

---

## License

MIT / Apache-2.0 — [LICENSE](../../README.md)

> ⚠️ هذا التطبيق لا يقدم استشارات طبية.
