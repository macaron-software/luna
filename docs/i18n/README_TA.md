<div align="center">

# LUNA — தமிழ்

**உங்கள் சுழற்சி. உங்கள் தொலைபேசி. எந்த சேவையகமும் இல்லை. எந்த கிளவுட்டும் இல்லை. பூஜ்ய சமரசம்.**

[![No server](https://img.shields.io/badge/server-none-brightgreen.svg)](#)
[![Offline](https://img.shields.io/badge/works-100%25%20offline-brightgreen.svg)](#)
[![License](https://img.shields.io/badge/license-MIT%20%2F%20Apache--2.0-blue.svg)](../../README.md)

</div>

[← English (full docs)](../../README.md)

---

## தனியுரிமை உறுதிமொழி

| | |
|---|---|
| 📵 | **எந்த சேவையகமும் இல்லை.** எங்களிடம் ஒன்றும் இல்லை. எந்த backend இல்லை, தொலை database இல்லை, பயன்பாடு இணைக்கும் API endpoint இல்லை. |
| 📶 | **100% ஆஃப்லைனில் செயல்படுகிறது.** இணைய இணைப்பு ஒருபோதும் தேவையில்லை மற்றும் பயன்படுத்தப்படுவதில்லை. ஒரு முறை நிறுவி, நெட்வொர்க் இல்லாமல் எப்போதும் பயன்படுத்துங்கள். |
| 🚷 | **கணக்கு இல்லை, பதிவு இல்லை.** மின்னஞ்சல் இல்லை, கடவுச்சொல் இல்லை, சமூக உள்நுழைவு இல்லை. எதுவும் இல்லை. |
| 🧩 | **மூன்றாம் தரப்பு சேவைகளில் சார்பு இல்லை.** Firebase, Google Analytics, Mixpanel, Sentry இல்லை. பூஜ்ய வெளிப்புற SDK. |
| 🔐 | **தரவு உங்கள் தொலைபேசியில் மட்டுமே மறைகுறியாக்கப்பட்டது.** AES-256-GCM மறைகுறியாக்கப்பட்ட SQLCipher database. PIN மூலம் Argon2id வழி பெறப்பட்ட திறவுகோல். திறவுகோல் ஒருபோதும் சாதனத்தை விட்டு வெளியேறாது. |
| ☁️ | **விருப்பமான கிளவுட் காப்புப்பிரதி — முழுமையாக மறைகுறியாக்கப்பட்டது.** iCloud/Google Drive ஒரு அபாரதர்சியமான மறைகுறியாக்கப்பட்ட blob ஐ மட்டுமே பெறுகிறது. Apple மற்றும் Google கூட அதை படிக்க முடியாது. |
| 🚫 | **பூஜ்ய telemetry, பூஜ்ய analytics.** crash report இல்லை, பயன்பாட்டு அளவீடுகள் இல்லை, A/B சோதனை இல்லை. எதுவும் உங்கள் தொலைபேசியை விட்டு வெளியேறாது. |
| 💥 | **3 வினாடிகளில் panic wipe.** பொத்தானை அழுத்தி வைக்கவும்: database + salt + அனைத்து cryptographic திறவுகோல்களும் மீளமுடியாமல் அழிக்கப்படும். |
| 🔓 | **100% திறந்த மூலம்.** MIT/Apache-2.0. ஒவ்வொரு code வரியும் பொது மற்றும் யாரும் தணிக்கை செய்யலாம். |

---

## LUNA ஒருபோதும் செய்யாதவை

| | |
|---|---|
| **சேவையகம் இல்லை** | எங்களிடம் இல்லை. உங்கள் தரவை அனுப்புவது இயலாது. |
| **இணையம் தேவையில்லை** | பயன்பாடு 100% ஆஃப்லைனில் செயல்படுகிறது. எப்போதும். |
| **கணக்கு இல்லை** | மின்னஞ்சல் இல்லை, கடவுச்சொல் இல்லை, உள்நுழைவு இல்லை. |
| **தரவு விற்பனை இல்லை** | இயலாது — நாங்கள் ஒருபோதும் பெறுவதில்லை. |
| **விளம்பரம் இல்லை** | பூஜ்ய விளம்பர SDK, பூஜ்ய tracking pixel. |
| **Push telemetry இல்லை** | நினைவூட்டல்கள் OS system ஐ மட்டுமே பயன்படுத்துகின்றன — சேவையகம் வழியாக தரவு இல்லை. |
| **மறைந்த SDK இல்லை** | binary இல் இந்த repository இல் நீங்கள் காண்பது மட்டுமே உள்ளது. |

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

## கட்டமைப்பு

```
பகிரப்பட்ட Rust core (UniFFI) · SwiftUI iOS · Kotlin Android · SQLCipher மறைகுறியாக்கம் · பூஜ்ய நெட்வொர்க்
```

---

## License

MIT / Apache-2.0 — [LICENSE](../../README.md)

> ⚠️ இந்த பயன்பாடு மருத்துவ ஆலோசனை வழங்காது.
