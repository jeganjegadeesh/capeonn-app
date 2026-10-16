#!/usr/bin/env bash
# ==============================================================================
# Capeonn Workplace Suite - CI/CD & Linux/macOS Multi-Platform Build Script
# ==============================================================================
set -euo pipefail

TARGETS=("${@:-all}")
CLEAN_BUILD=false

for arg in "$@"; do
    if [[ "$arg" == "--clean" ]]; then
        CLEAN_BUILD=true
    fi
done

echo "=========================================================="
echo "   Capeonn Workplace Suite - Multi-Platform Build Engine   "
echo "=========================================================="

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$APP_DIR"

if [ "$CLEAN_BUILD" = true ]; then
    echo "[1/4] Cleaning build artifacts..."
    flutter clean
fi

echo "[2/4] Fetching Flutter dependencies..."
flutter pub get

SYMBOL_DIR="$APP_DIR/build/symbols"
mkdir -p "$SYMBOL_DIR/android" "$SYMBOL_DIR/ios"

build_all=false
for target in "${TARGETS[@]}"; do
    if [[ "$target" == "all" ]]; then
        build_all=true
    fi
done

# 1. Android
if [ "$build_all" = true ] || [[ " ${TARGETS[*]} " =~ " android " ]]; then
    echo "[3/4] Building Android App Bundle (AAB) & Split APKs..."
    flutter build appbundle --release --obfuscate --split-debug-info="$SYMBOL_DIR/android"
    flutter build apk --release --split-per-abi --obfuscate --split-debug-info="$SYMBOL_DIR/android"
    echo "  [OK] Android artifacts built."
fi

# 2. Web PWA
if [ "$build_all" = true ] || [[ " ${TARGETS[*]} " =~ " web " ]]; then
    echo "[4/4] Building Web PWA (CanvasKit + Offline Service Worker)..."
    flutter build web --release --pwa-strategy=offline-first --web-renderer canvaskit
    echo "  [OK] Web bundle output at: build/web/"
fi

# 3. iOS (Only on macOS)
if [ "$build_all" = true ] || [[ " ${TARGETS[*]} " =~ " ios " ]]; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "Building iOS Archive..."
        flutter build ipa --release --obfuscate --split-debug-info="$SYMBOL_DIR/ios"
        echo "  [OK] iOS IPA built."
    else
        echo "Skipping iOS build (requires macOS runner)."
    fi
fi

echo "=========================================================="
echo "Build complete. Symbols stored in $SYMBOL_DIR"
echo "=========================================================="
