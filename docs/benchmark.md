# LUNA — Benchmark concurrentiel

> Comparaison vs Flo · Clue · Natural Cycles · mise à jour 2026-03-05

---

## Features — état implémenté

| Feature | Flo | Clue | Natural Cycles | **LUNA** |
|---------|:---:|:----:|:--------------:|:--------:|
| Suivi période (date, durée, flux) | Oui | Oui | Oui | **Oui** |
| Symptômes catégorisés | Partiel | Partiel | Non | **43** (mens · SPM · ovul · follicul · péri-méno) |
| Humeur 1–5 | Emoji | Emoji | Non | **Oui** — cercles numériques, sans emoji |
| Energie 1–5 | Non | Oui | Non | **Oui** |
| Sommeil 1–5 | Oui | Oui | Non | **Oui** |
| Poids (kg) | Oui (Premium) | Non | Non | **Oui** |
| Température basale (BBT) | Oui | Oui | Oui | **Oui** |
| Test LH ovulation | Oui | Oui | Oui | **Oui** |
| Mucus cervical (5 types) | Oui | Oui | Oui | **Oui** |
| Activité sexuelle | Oui | Oui | Non | **Oui** |
| Notes libres | Oui | Oui | Oui | **Oui** |
| Prédictions cycle / ovulation | IA cloud | IA cloud | Algo serveur | **On-device** |
| Fenêtre fertile | Oui | Oui | Oui | **Oui** |
| Calendrier | Oui | Oui | Oui | **Oui** |
| Insights / statistiques | Oui | Oui | Oui | **Oui** |
| Export backup chiffré | Non | Non | Non | **Oui** AES-256-GCM |
| Dark mode auto (système) | Oui | Oui | Oui | **Oui** |
| i18n | 22 langues | 15 langues | 12 langues | **40 langues** |
| RTL (arabe, hébreu, persan) | Partiel | Non | Non | **Oui** — testé sur simulateur |
| WCAG 2.2 AA | Partiel | Partiel | Non | **Oui** |
| Mode Calm (accessibilité psy) | Non | Non | Non | **Oui** — unique |
| Reduce Motion (animation) | Non | Non | Non | **Oui** |
| PIN + Keychain / Keystore | Non | Non | Non | **Oui** |
| Panic wipe | Non | Non | Non | **Oui** — unique |
| Zéro réseau / zéro serveur | Non | Non | Non | **Oui** |
| Données locales chiffrées | Partiel | Partiel | Partiel | **Oui** AES-256 + Argon2id |
| Données revendables | Oui (Flo) | Non | Non | **Impossible par construction** |
| Zéro emoji dans l'UI | Non | Non | Non | **Oui** |
| Compression stockage local | Non | Non | Non | **Oui** — zstd BLOB |

---

## Gaps restants — backlog priorisé

| Feature manquante | Priorité | Notes |
|-------------------|:--------:|-------|
| Notifications locales (rappel période, ovulation) | **Haute** | Permissions déclarées, logique non implémentée |
| Mode TTC / grossesse (test hCG, kicks, suivi) | **Haute** | Absent du modèle de données |
| HealthKit (iOS) / HealthConnect (Android) bridge | Moyenne | Permissions déclarées, bridge non codé |
| Authentification biométrique (FaceID / empreinte) | Moyenne | BiometricPrompt déclaré, non branché |
| Export CSV / PDF lisible | Moyenne | Seul backup binaire chiffré disponible |
| Rappel prise pilule / contraception | Moyenne | |
| Graphiques de tendance (BBT, poids, cycle) | Moyenne | InsightsView existant, courbes absentes |
| Mode péri-ménopause dédié | Basse | Symptômes présents (hot_flash, night_sweats), UI non dédiée |
| Apple Watch / Wear OS companion | Basse | Hors scope initial |

---

## Compatibilité appareils

| Plateforme | Version minimum | Couverture estimée |
|------------|----------------|-------------------|
| Android | **API 23** — Android 6.0 Marshmallow (oct 2015) | ~98 % appareils actifs |
| iOS | **16.0** — septembre 2022 | ~95 % iPhones actifs |
| ABI Android | arm64-v8a · armeabi-v7a · x86_64 | 32-bit ARM inclus |

> **Pourquoi iOS 16 minimum ?**
> `NavigationStack` et `.presentationDetents` sont iOS 16+. Descendre à iOS 15
> nécessiterait remplacer par `NavigationView` + sheet custom — faible ROI car le
> taux de mise à jour iOS est élevé (>95 % sur iOS 15+ dès 2024).

> **Pourquoi Android 23 (et non 26) ?**
> Android Keystore AES-256-GCM disponible depuis API 23. HealthConnect (API 26)
> est optionnel et détecté à l'exécution. BiometricPrompt via AndroidX supporte
> API 21+. Passer de 26 à 23 couvre ~3 % d'appareils supplémentaires, surtout
> dans les marchés émergents.

---

## Positionnement résumé

| Axe | LUNA vs concurrents |
|-----|---------------------|
| Privacy | Seul à garantir zéro collecte **par architecture** (pas de réseau possible) |
| Sécurité locale | Seul avec Argon2id + AES-256-GCM + panic wipe + backup chiffré |
| Accessibilité | Seul avec Calm Mode (psy), reduceMotion, 40 langues, RTL complet |
| Algorithme | Seul on-device (pas de cloud requis) |
| Prix | Gratuit, open source partiel (AGPL-3.0 core) |
| Données | Impossible à revendre (stockage local uniquement) |
