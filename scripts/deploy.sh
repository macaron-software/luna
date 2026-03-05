#!/usr/bin/env bash
# LUNA Deploy Script
# Usage: ./scripts/deploy.sh ios|android|both

set -e

PLATFORM=${1:-both}
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "=== LUNA Deploy ==="
echo "Platform: $PLATFORM"

build_ios() {
  echo ""
  echo "--- iOS: Building Rust core ---"
  cd "$REPO_ROOT"
  IPHONEOS_DEPLOYMENT_TARGET=16.0 cargo build --target aarch64-apple-ios --release -p luna-core
  cp target/aarch64-apple-ios/release/libluna_core.a ios-app/LunaApp/Generated/libluna_core.a

  echo "--- iOS: Archiving ---"
  IPHONEOS_DEPLOYMENT_TARGET=16.0 xcodebuild archive \
    -project ios-app/LunaApp.xcodeproj \
    -scheme LunaApp \
    -archivePath /tmp/LunaApp.xcarchive \
    CODE_SIGN_STYLE=Manual \
    DEVELOPMENT_TEAM=P36X572LL9 \
    CODE_SIGN_IDENTITY="Apple Distribution" \
    PROVISIONING_PROFILE_SPECIFIER="LUNA App Store Distribution" \
    | grep -E "(BUILD|error:|ARCHIVE)" | tail -5

  echo "--- iOS: Exporting IPA ---"
  rm -rf /tmp/LunaApp_export
  xcodebuild -exportArchive \
    -archivePath /tmp/LunaApp.xcarchive \
    -exportPath /tmp/LunaApp_export \
    -exportOptionsPlist "$REPO_ROOT/fastlane/ExportOptions.plist" \
    | tail -3

  echo "--- iOS: Uploading to App Store Connect ---"
  xcrun altool --upload-app \
    --type ios \
    --file /tmp/LunaApp_export/LUNA.ipa \
    --apiKey "${ASC_KEY_ID:-48GLJZYX5K}" \
    --apiIssuer "${ASC_ISSUER_ID:-69a6de74-3cdf-47e3-e053-5b8c7c11a4d1}"
  echo "iOS: Upload complete!"
}

build_android() {
  echo ""
  echo "--- Android: Building AAB ---"
  cd "$REPO_ROOT/android-app"
  ./gradlew bundleRelease --quiet

  AAB_PATH="$REPO_ROOT/android-app/app/build/outputs/bundle/release/app-release.aab"
  echo "AAB: $AAB_PATH ($(du -h "$AAB_PATH" | cut -f1))"

  if [ -n "$GOOGLE_PLAY_JSON_KEY" ]; then
    echo "--- Android: Uploading to Play Store ---"
    /opt/homebrew/lib/ruby/gems/4.0.0/bin/fastlane android upload
    echo "Android: Upload complete!"
  else
    echo "Android: AAB ready at $AAB_PATH"
    echo "To upload: Set GOOGLE_PLAY_JSON_KEY path and run: fastlane android upload"
    echo "Or drag-drop to: https://play.google.com/console"
  fi
}

case "$PLATFORM" in
  ios)     build_ios ;;
  android) build_android ;;
  both)    build_ios && build_android ;;
  *)       echo "Usage: $0 ios|android|both" && exit 1 ;;
esac

echo ""
echo "=== Deploy complete ==="
