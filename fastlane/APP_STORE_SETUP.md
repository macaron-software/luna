# App Store Setup Guide

## Prerequisites

### 1. App Store Connect API Key

Already configured:
- Key ID: `48GLJZYX5K`
- Issuer ID: `69a6de74-3cdf-47e3-e053-5b8c7c11a4d1`
- Key file: `~/.appstoreconnect/private_keys/AuthKey_48GLJZYX5K.p8`

### 2. Create App in App Store Connect (first time)

1. [appstoreconnect.apple.com](https://appstoreconnect.apple.com) → My Apps → +
2. New App → iOS
3. Bundle ID: `com.macaron.luna`
4. SKU: `luna-cycle-tracker`
5. Name: **LUNA – Cycle & Wellness Tracker**

### 3. Upload via Fastlane

```bash
# Build IPA + upload to TestFlight
bundle exec fastlane ios release

# Upload only metadata + screenshots
bundle exec fastlane ios upload_metadata

# Upload already-built IPA to TestFlight
bundle exec fastlane ios upload_testflight
```

## Files Ready

| File | Status |
|------|--------|
| `fastlane/metadata/ios/en-US/` | ✅ Full metadata |
| `fastlane/metadata/ios/fr-FR/` | ✅ French |
| `fastlane/metadata/ios/de-DE/` | ✅ German |
| `fastlane/metadata/ios/es-ES/` | ✅ Spanish |
| `fastlane/metadata/ios/ja/` | ✅ Japanese |
| Screenshots (1290×2796) 6 screens × 8 langs | ✅ Generated |

## Build Requirements

- Apple Distribution certificate in Keychain
- Provisioning profile: "LUNA App Store Distribution"
- Team ID: `P36X572LL9`

```bash
# Build IPA manually
bundle exec fastlane ios build
```
