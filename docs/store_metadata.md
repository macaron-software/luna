# LUNA — Store Metadata v0.1.0

## App Info

| Field | Value |
|-------|-------|
| **App name** | LUNA — Cycle & Wellness |
| **Subtitle (iOS)** | Private. Local. Yours. |
| **Bundle ID (iOS)** | app.luna |
| **Package (Android)** | app.luna |
| **Category** | Health & Fitness |
| **Sub-category** | Women's Health |
| **Age rating** | 12+ (iOS) / Teen (Android) |
| **Version** | 0.1.0 (build 1) |
| **Privacy Policy URL** | https://luna-health.github.io/luna/privacy |

---

## Short Description (80 chars max — Google Play)

```
Track your cycle privately. AES-256 encrypted. Zero cloud. 100% yours.
```

## Long Description — English

LUNA is a science-based menstrual cycle tracker that puts your privacy first.

**Everything stays on your device.** There are no servers, no analytics, no ads, and no account required. Your cycle data is encrypted with AES-256 (SQLCipher) and can only be unlocked with your PIN or biometrics.

### Features

- **Cycle tracking** — Log period start/end, flow intensity, symptoms, mood, energy, basal body temperature
- **Predictions** — Algorithm based on your personal cycle history (not population averages)
- **Fertile window** — Calculated from your data using evidence-based methods
- **4 tracking modes** — Regular cycles, TTC (trying to conceive), pregnancy, perimenopause
- **Symptoms library** — 30+ symptoms across physical, emotional and wellness categories
- **Medications & contraception** — Log pill, patch, IUD, implant reminders
- **Pregnancy mode** — Week-by-week guidance with local notifications
- **Export** — Encrypted backup or CSV export for your doctor
- **Dark mode** — Automatic, follows system
- **40 languages** — Full i18n including RTL (Arabic, Hebrew, Farsi)
- **Accessibility** — Screen reader support, high contrast, reduced motion

### Privacy by design

- AES-256 encrypted local database (SQLCipher)
- Argon2id key derivation from your PIN
- Biometric unlock (Face ID / Touch ID / Fingerprint)
- No account, no email, no tracking
- No analytics SDK, no crash reporting to servers
- Open source — audit the code yourself

### Science-based

Predictions use a personal Kalman-filter model updated with each cycle. Fertile window estimates follow ACOG and WHO guidelines. Perimenopause mode surfaces evidence-based symptom correlation patterns from peer-reviewed research.

---

## Long Description — French

LUNA est un suivi de cycle menstruel basé sur des preuves scientifiques, qui place votre vie privée au premier plan.

**Tout reste sur votre appareil.** Pas de serveur, pas d'analytique, pas de publicités, pas de compte requis. Vos données de cycle sont chiffrées en AES-256 (SQLCipher) et déverrouillables uniquement par votre code PIN ou votre biométrie.

### Fonctionnalités

- **Suivi du cycle** — Début/fin des règles, intensité, symptômes, humeur, énergie, température basale
- **Prédictions** — Algorithme basé sur votre historique personnel
- **Fenêtre fertile** — Calculée selon les méthodes fondées sur des preuves (ACOG/OMS)
- **4 modes de suivi** — Cycles réguliers, TTC (désir de grossesse), grossesse, péri-ménopause
- **40 langues** dont arabe, hébreu, farsi (RTL)
- **Accessibilité** — VoiceOver/TalkBack, contraste élevé, mouvement réduit
- **Export** — Sauvegarde chiffrée ou CSV pour votre médecin

### Confidentialité totale

Aucune donnée n'est envoyée à un serveur. Base de données chiffrée AES-256, dérivation de clé Argon2id. Code open source.

---

## Keywords (iOS — 100 chars)

```
cycle tracker,period,fertility,ovulation,private,no cloud,encrypted,women health,TTC,menstrual
```

## Keywords (Google Play — tags)

```
period tracker, cycle tracking, fertility, ovulation, menstrual calendar, private health, encrypted, women's health, TTC, no account
```

---

## Content Rating Questionnaire (Google Play)

| Question | Answer |
|----------|--------|
| Violence | None |
| Sexual content | None |
| Language | None |
| Drugs/alcohol | None |
| Gambling | None |
| User-generated content | No |
| Personal/sensitive data | Yes — health (stored locally only) |
| **Expected rating** | **Everyone (PEGI 3 / ESRB E)** |

---

## Data Safety (Google Play — mandatory)

| Data type | Collected | Shared | Required | Optional |
|-----------|-----------|--------|----------|----------|
| Health info (menstrual) | No (local only) | No | — | — |
| Personal info (name, email) | No | No | — | — |
| Location | No | No | — | — |
| Device IDs | No | No | — | — |
| Crash logs | No | No | — | — |

**Data collection:** No data is collected or transmitted.  
**Security practices:** Data is encrypted in transit (N/A — no transit) and at rest (AES-256).  
**Deletion:** Users can delete all data via Settings → Wipe.

---

## App Store Review Notes (iOS)

- App requires no account or login
- All health data stored locally in encrypted SQLite (SQLCipher)
- HealthKit integration is optional — app works fully without it
- No internet permission required
- Test with: PIN = 1234 (any 4–8 digit code works on first launch)

---

## What's New — v0.1.0

Initial release of LUNA:
- Cycle tracking with AES-256 local encryption
- 4 tracking modes (regular, TTC, pregnancy, perimenopause)
- Predictions and fertile window
- 40 languages, dark mode, full accessibility
- No account, no cloud, no tracking
