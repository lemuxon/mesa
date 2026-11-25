#!/usr/bin/env bash
# Downloads TDLib (Telegram's official client library), built from the official
# source by this repository's "TDLib Android" workflow, verifies its SHA256 and
# places it into the Android project (jniLibs + org.drinkless.tdlib Java
# sources). Both are git-ignored; run once in a fresh clone before building.
#
# GitHub Actions'ta resmi kaynaktan derlenen TDLib'i indirir, SHA256'sını
# doğrular ve Android projesine yerleştirir. Giriş gerekmez (herkese açık sürüm).
set -euo pipefail

TAG="tdlib-1.8.68-c15d3f5"
REPO="lemuxon/mesa"
FILE="tdlib-android-1.8.68.zip"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

BASE="https://github.com/$REPO/releases/download/$TAG"
curl -fsSL -o "$TMP/$FILE" "$BASE/$FILE"
curl -fsSL -o "$TMP/$FILE.sha256" "$BASE/$FILE.sha256"
(cd "$TMP" && sha256sum -c "$FILE.sha256")
unzip -q "$TMP/$FILE" -d "$TMP/x"

JNI="$ROOT/android/app/src/main/jniLibs"
JAVA="$ROOT/android/app/src/main/java/org/drinkless"
rm -rf "$JNI" "$JAVA"
mkdir -p "$JNI" "$(dirname "$JAVA")"
cp -r "$TMP/x/tdlib/libs/." "$JNI/"
cp -r "$TMP/x/tdlib/java/org/drinkless" "$JAVA"

echo "TDLib ($TAG) installed:"
find "$JNI" -name '*.so' -exec ls -la {} \;
ls -la "$JAVA/tdlib"
