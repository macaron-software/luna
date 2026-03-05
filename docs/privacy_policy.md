# LUNA — Privacy Policy

**Effective date:** March 2026  
**App:** LUNA — Cycle & Wellness Tracker  
**Developer:** Luna Health

---

## 1. Summary

LUNA is a **100% local** app. Your health data never leaves your device unless you explicitly choose to export or back up to your personal iCloud / Google Drive account.

| Data | Where it goes |
|------|--------------|
| Cycle logs, symptoms, moods | Your device only (encrypted) |
| PIN / biometric | Your device secure enclave |
| Notifications | Scheduled locally, never to a server |
| Analytics, ads, tracking | **None** |

---

## 2. Data we collect

LUNA collects **only** the data you enter:

- Cycle dates, period flow, predicted dates
- Daily symptoms, mood, energy, basal body temperature
- Notes you write yourself
- Notification preferences

We do **not** collect:
- Device identifiers, IDFA, or advertising IDs
- Location data
- Contact information
- Browsing history or cross-app tracking
- Crash analytics or usage analytics transmitted to any server

---

## 3. How data is stored

All data is stored locally on your device in an **AES-256 encrypted database** (SQLCipher), compressed with zstd. The encryption key is derived from your PIN using Argon2id.

On iOS, you may optionally enable iCloud backup — this is governed by Apple's own privacy policy and encryption. On Android, Google Drive backup follows Google's policy.

---

## 4. HealthKit (iOS)

If you grant HealthKit access, LUNA can read/write menstrual cycle data to Apple Health. This data stays on your device and is subject to Apple's HealthKit data rules. You can revoke access at any time in iOS Settings → Health → Data Access.

---

## 5. Health Connect (Android)

If you grant Health Connect access, LUNA can sync cycle data. You can revoke access at any time in Android Settings → Health Connect.

---

## 6. Data sharing

We **never** share, sell, or transmit your personal health data to:
- Third-party analytics companies
- Advertising networks
- Social media platforms
- Any server operated by us or others

---

## 7. Children

LUNA is intended for users 17 and older. We do not knowingly collect data from children under 13 (US) / 16 (EU).

---

## 8. Your rights (GDPR / CCPA)

Since all data is local, you control it entirely:
- **Access:** open the app
- **Delete:** Settings → Wipe All Data (irreversible)
- **Export:** Settings → Export Data (encrypted backup)
- **Portability:** CSV export available

---

## 9. Changes

We will update this policy if LUNA adds new features that affect privacy. The "Effective date" above will change. No retroactive changes to data practices.

---

## 10. Contact

Questions? Open an issue on [GitHub](https://github.com/luna-health/luna) or email: privacy@luna-health.app

---

*LUNA is open-source (MIT/Apache-2.0). You can audit every line of code that handles your data.*
