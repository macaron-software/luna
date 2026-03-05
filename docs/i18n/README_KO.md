<div align="center">

# LUNA — 한국어

**당신의 주기. 당신의 전화기. 서버 없음. 클라우드 없음. 타협 없음.**

[![No server](https://img.shields.io/badge/server-none-brightgreen.svg)](#)
[![Offline](https://img.shields.io/badge/works-100%25%20offline-brightgreen.svg)](#)
[![License](https://img.shields.io/badge/license-MIT%20%2F%20Apache--2.0-blue.svg)](../../README.md)

</div>

[← English (full docs)](../../README.md)

---

## 개인정보 약속

| | |
|---|---|
| 📵 | **서버 없음.** 우리는 서버가 없습니다. 백엔드 없음, 원격 데이터베이스 없음, 앱이 연결하는 API 엔드포인트 없음. |
| 📶 | **100% 오프라인 작동.** 인터넷 연결이 필요하거나 사용된 적이 없습니다. 한 번 설치하면 네트워크 없이 영원히 사용 가능합니다. |
| 🚷 | **계정 없음, 가입 없음.** 이메일 없음, 비밀번호 없음, 소셜 로그인 없음, 신원 확인 없음. 아무것도 없습니다. |
| 🧩 | **타사 서비스 의존성 없음.** Firebase, Google Analytics, Mixpanel, Sentry, Amplitude 없음. 외부 SDK 제로. |
| 🔐 | **데이터는 전화기에만 암호화 저장.** AES-256-GCM으로 암호화된 SQLCipher 데이터베이스. Argon2id를 통해 PIN에서 파생된 키. 키는 장치를 절대 떠나지 않습니다. |
| ☁️ | **선택적 클라우드 백업 — 완전 암호화.** iCloud/Google Drive는 불투명한 암호화된 블롭을 받습니다. Apple과 Google도 읽을 수 없습니다. |
| 🚫 | **텔레메트리 제로, 분석 제로.** 충돌 보고서 없음, 사용 메트릭 없음, A/B 테스트 없음. 전화기를 떠나는 것은 아무것도 없습니다. |
| 💥 | **3초 패닉 와이프.** 버튼을 길게 누르세요: 데이터베이스 + 솔트 + 모든 암호화 키가 되돌릴 수 없이 파괴됩니다. |
| 🔓 | **100% 오픈 소스.** MIT/Apache-2.0. 모든 코드 줄이 공개되어 있고 누구나 감사할 수 있습니다. |

---

## LUNA가 절대 하지 않을 일

| | |
|---|---|
| **서버 없음** | 우리는 없습니다. 데이터를 어디에도 보낼 수 없습니다. |
| **인터넷 불필요** | 앱은 100% 오프라인으로 작동합니다. 항상. |
| **계정 없음** | 이메일 없음, 비밀번호 없음, 로그인 없음. |
| **데이터 판매 없음** | 불가능 — 우리는 절대 수신하지 않습니다. |
| **광고 없음** | 광고 SDK 제로, 추적 픽셀 제로. |
| **푸시 텔레메트리 없음** | 알림은 OS 시스템만 사용 — 서버를 통한 데이터 없음. |
| **숨겨진 SDK 없음** | 바이너리에는 이 저장소에서 보는 것만 포함됩니다. |

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

## 아키텍처

```
공유 Rust 코어 (UniFFI) · SwiftUI iOS · Kotlin Android · SQLCipher 암호화 · 제로 네트워크
```

---

## License

MIT / Apache-2.0 — [LICENSE](../../README.md)

> ⚠️ 이 앱은 의료 조언을 제공하지 않습니다.
