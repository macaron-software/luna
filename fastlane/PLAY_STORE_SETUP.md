# Play Store Setup Guide

## Prerequisites

### 1. Google Play Console Service Account JSON

1. Go to [Google Play Console](https://play.google.com/console)
2. Setup > API access > Create new service account
3. Grant **Release manager** permission
4. Download JSON key → save as `fastlane/google-play-key.json`

### 2. Create App in Play Console (first time)

1. Play Console → All apps → Create app
2. App name: **LUNA - Cycle & Wellness Tracker**
3. Default language: **English (United States)**
4. App category: **Health & Fitness**
5. Free app

### 3. Upload via Fastlane

```bash
# Upload AAB + all metadata + screenshots (first upload: use console manually)
cd /path/to/luna
GOOGLE_PLAY_JSON_KEY=fastlane/google-play-key.json \
  bundle exec fastlane android upload_internal

# Or just metadata + screenshots without binary
bundle exec fastlane android upload_store_assets
```

### 4. Manual First Upload

For the very first upload, Google requires uploading via the Play Console UI:

1. Play Console → Your app → Production/Internal testing
2. Create new release → Upload AAB:
   `android-app/app/build/outputs/bundle/release/app-release.aab`
3. Version: **0.1.0 (1)**
4. After first upload, subsequent uploads work via fastlane

## Files Ready

| File | Status |
|------|--------|
| `app-release.aab` (9.8 MB signed) | ✅ Built & signed |
| `fastlane/metadata/android/en-US/` | ✅ Title, description, short desc |
| `fastlane/metadata/android/fr-FR/` | ✅ French |
| `fastlane/metadata/android/de-DE/` | ✅ German |
| `fastlane/metadata/android/es-ES/` | ✅ Spanish |
| `fastlane/metadata/android/ja-JP/` | ✅ Japanese |
| `fastlane/metadata/android/zh-CN/` | ✅ Chinese Simplified |
| `fastlane/metadata/android/ko-KR/` | ✅ Korean |
| `fastlane/metadata/android/pt-BR/` | ✅ Portuguese (Brazil) |
| `fastlane/metadata/android/it-IT/` | ✅ Italian |
| `fastlane/metadata/android/nl-NL/` | ✅ Dutch |
| `fastlane/metadata/android/ar-SA/` | ✅ Arabic |
| `fastlane/metadata/android/ru-RU/` | ✅ Russian |
| Screenshots (1080×1920) 6 screens × 8 langs | ✅ Generated |
| Feature graphic (1024×500) × 8 langs | ✅ Generated |

## Keystore

```
Location:  android-app/keystore/luna-release.jks
Alias:     luna
SHA-256:   F3:7A:E2:FC:24:C3:8A:86:F3:17:2E:3A:28:38:00:C1:...
```

⚠️ **Back up the keystore!** You CANNOT update the app without it.
