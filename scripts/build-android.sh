#!/usr/bin/env bash
# build-android.sh — Compile luna-core pour Android (toutes ABI) via cargo-ndk
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$SCRIPT_DIR/.."
CORE="$ROOT/luna-core"
JNI_LIBS="$ROOT/android-app/app/src/main/jniLibs"

echo "🦀 Building luna-core for Android targets..."

cd "$CORE"

# Vérifier que cargo-ndk est installé
if ! command -v cargo-ndk &>/dev/null; then
  echo "❌ cargo-ndk requis : cargo install cargo-ndk"
  exit 1
fi

# Build pour toutes les ABI Android
cargo ndk \
  --target aarch64-linux-android \
  --target armv7-linux-androideabi \
  --target x86_64-linux-android \
  --platform 26 \
  -- build --release

# Copier les .so vers jniLibs
echo "📦 Copying .so files to jniLibs..."
mkdir -p "$JNI_LIBS/arm64-v8a"
mkdir -p "$JNI_LIBS/armeabi-v7a"
mkdir -p "$JNI_LIBS/x86_64"

cp "target/aarch64-linux-android/release/libluna_core.so"    "$JNI_LIBS/arm64-v8a/"
cp "target/armv7-linux-androideabi/release/libluna_core.so"  "$JNI_LIBS/armeabi-v7a/"
cp "target/x86_64-linux-android/release/libluna_core.so"     "$JNI_LIBS/x86_64/"

# Générer les bindings Kotlin
echo "📦 Generating Kotlin bindings..."
KOTLIN_OUT="$ROOT/android-app/app/src/main/kotlin/dev/luna/generated"
mkdir -p "$KOTLIN_OUT"

cargo run --features=uniffi/cli -- \
  generate src/luna_core.udl --language kotlin \
  --out-dir "$KOTLIN_OUT" 2>/dev/null || \
echo "⚠️  uniffi-bindgen Kotlin : génération manuelle requise (voir README)"

echo "✅ Android .so files déployés dans $JNI_LIBS"
