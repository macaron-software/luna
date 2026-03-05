# Fastlane Setup

## Local Deployment

### iOS

Requires macOS with Xcode and the Apple Distribution certificate in keychain.

```bash
# Full build + upload (once app is created on ASC)
./scripts/deploy.sh ios

# Or step by step:
fastlane ios build          # Build IPA
fastlane ios upload         # Upload to App Store Connect
fastlane ios upload_metadata # Upload metadata + screenshots
```

### Android

```bash
# Build AAB
./scripts/deploy.sh android

# Upload (requires Google Play service account JSON key)
GOOGLE_PLAY_JSON_KEY=/path/to/key.json fastlane android upload
```

## GitHub Actions (CI/CD)

Set these secrets in GitHub repository settings (Settings > Secrets > Actions):

| Secret | Description |
|--------|-------------|
| `ASC_KEY_ID` | App Store Connect API Key ID (`48GLJZYX5K`) |
| `ASC_ISSUER_ID` | App Store Connect Issuer ID |
| `ASC_PRIVATE_KEY` | Content of `AuthKey_48GLJZYX5K.p8` |
| `IOS_PROVISIONING_PROFILE` | Base64-encoded `.mobileprovision` |
| `IOS_CERTIFICATE_P12` | Base64-encoded Apple Distribution `.p12` |
| `IOS_CERTIFICATE_PASSWORD` | P12 certificate password |
| `ANDROID_KEYSTORE_BASE64` | Base64-encoded `luna-release.jks` |
| `ANDROID_STORE_PASSWORD` | Keystore password |
| `ANDROID_KEY_PASSWORD` | Key alias password |
| `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` | Google Play service account JSON |

### Encode secrets for GitHub:

```bash
# Provisioning profile
base64 -i ~/Library/MobileDevice/Provisioning\ Profiles/luna-appstore-distribution.mobileprovision | pbcopy

# Android keystore
base64 -i android-app/keystore/luna-release.jks | pbcopy

# iOS P12 (export from Keychain Access > My Certificates > Apple Distribution)
base64 -i /path/to/AppleDistribution.p12 | pbcopy
```

## Google Play Service Account Setup

1. Go to [Google Play Console](https://play.google.com/console) > Setup > API access
2. Link to a Google Cloud project
3. Create a service account with "Release manager" role
4. Download the JSON key
5. Add as `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` secret in GitHub

## Triggers

- Push a tag `v*` to trigger automatic release
- Or manually trigger via GitHub Actions > Release > Run workflow
