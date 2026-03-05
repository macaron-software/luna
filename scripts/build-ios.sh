#!/usr/bin/env bash
# build-ios.sh — Compile luna-core pour iOS et génère le XCFramework
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$SCRIPT_DIR/.."
CORE="$ROOT/luna-core"
OUTPUT="$ROOT/ios-app/Frameworks"

echo "🦀 Building luna-core for iOS targets..."

cd "$CORE"

# Targets iOS
cargo build --release --target aarch64-apple-ios          # device arm64
cargo build --release --target aarch64-apple-ios-sim      # simulator arm64 (M1/M2)
cargo build --release --target x86_64-apple-ios           # simulator x86_64

# Créer une fat lib simulator (arm64 + x86_64) pour Simulator
mkdir -p "$OUTPUT/sim"
lipo -create \
  "target/aarch64-apple-ios-sim/release/libluna_core.a" \
  "target/x86_64-apple-ios/release/libluna_core.a" \
  -output "$OUTPUT/sim/libluna_core.a"

# Générer les bindings Swift via uniffi-bindgen
echo "📦 Generating Swift bindings..."
cargo run --bin uniffi-bindgen-cli --manifest-path ../Cargo.toml -- \
  generate --library target/aarch64-apple-ios/release/libluna_core.a \
  --language swift \
  --out-dir "$OUTPUT/Generated" 2>/dev/null || \
cargo run --features=uniffi/cli -- \
  generate src/luna_core.udl --language swift --out-dir "$OUTPUT/Generated" 2>/dev/null || \
echo "⚠️  uniffi-bindgen : génération manuelle requise (voir README)"

# Assembler le XCFramework
echo "📦 Creating XCFramework..."
mkdir -p "$OUTPUT"
rm -rf "$OUTPUT/luna_core.xcframework"

xcodebuild -create-xcframework \
  -library "target/aarch64-apple-ios/release/libluna_core.a" \
  -headers "$OUTPUT/Generated" \
  -library "$OUTPUT/sim/libluna_core.a" \
  -headers "$OUTPUT/Generated" \
  -output "$OUTPUT/luna_core.xcframework"

echo "✅ luna_core.xcframework créé dans $OUTPUT"
