#!/usr/bin/env bash

set -Eeuo pipefail

usage() {
  cat <<'EOF'
Build openIMIS Android APKs.

Usage:
  ./scripts/build_android_apks.sh [all|debug|release]

Environment variables:
  FLUTTER_BIN    Flutter executable (default: flutter from PATH)
  DART_BIN       Dart executable (default: dart next to FLUTTER_BIN)
  CLEAN_BUILD    Set to 1 to run flutter clean first
  SKIP_CODEGEN   Set to 1 to skip build_runner generation

Outputs:
  outputs/android/openimis-claim-policy-<version>-dev-debug.apk
  outputs/android/openimis-claim-policy-<version>-prod-release.apk
EOF
}

mode="${1:-all}"
case "$mode" in
  all|debug|release) ;;
  -h|--help)
    usage
    exit 0
    ;;
  *)
    echo "Unknown build mode: $mode" >&2
    usage >&2
    exit 2
    ;;
esac

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
project_dir="$(cd "$script_dir/.." && pwd)"
cd "$project_dir"

flutter_bin="${FLUTTER_BIN:-$(command -v flutter || true)}"
if [[ -z "$flutter_bin" || ! -x "$flutter_bin" ]]; then
  echo "Flutter was not found. Set FLUTTER_BIN to your Flutter executable." >&2
  exit 1
fi

dart_bin="${DART_BIN:-$(dirname "$flutter_bin")/dart}"
if [[ ! -x "$dart_bin" ]]; then
  echo "Dart was not found next to Flutter. Set DART_BIN explicitly." >&2
  exit 1
fi

for env_file in .env.dev .env.prod; do
  if [[ ! -f "$env_file" ]]; then
    echo "Missing $env_file. Copy .env.example and configure it first." >&2
    exit 1
  fi
done

app_version="$(awk '/^version:/ { print $2; exit }' pubspec.yaml)"
if [[ -z "$app_version" ]]; then
  echo "Unable to read the version from pubspec.yaml." >&2
  exit 1
fi
file_version="${app_version/+/_}"
output_dir="$project_dir/outputs/android"
mkdir -p "$output_dir"

if [[ "${CLEAN_BUILD:-0}" == "1" ]]; then
  "$flutter_bin" clean
fi

"$flutter_bin" pub get

if [[ "${SKIP_CODEGEN:-0}" != "1" ]]; then
  "$dart_bin" run build_runner build --delete-conflicting-outputs
fi

build_debug() {
  echo "Building dev debug APK..."
  "$flutter_bin" build apk \
    --debug \
    --flavor dev \
    --target lib/main/main_dev.dart \
    --no-pub

  local source_apk="build/app/outputs/flutter-apk/app-dev-debug.apk"
  local target_apk="$output_dir/openimis-claim-policy-${file_version}-dev-debug.apk"
  cp "$source_apk" "$target_apk"
  echo "Created $target_apk"
}

build_release() {
  if [[ ! -f android/key.properties ]]; then
    echo "Warning: android/key.properties is absent; the current Gradle fallback signing configuration will be used." >&2
  fi

  echo "Building optimized prod release APK..."
  "$flutter_bin" build apk \
    --release \
    --split-per-abi \
    --flavor prod \
    --target lib/main/main_prod.dart \
    --no-pub

  local abi
  for abi in armeabi-v7a arm64-v8a x86_64; do
    local source_apk="build/app/outputs/flutter-apk/app-${abi}-prod-release.apk"
    local target_apk="$output_dir/openimis-claim-policy-${file_version}-prod-${abi}.apk"
    cp "$source_apk" "$target_apk"
    echo "Created $target_apk"
  done
}

case "$mode" in
  debug) build_debug ;;
  release) build_release ;;
  all)
    build_debug
    build_release
    ;;
esac

echo "Android APK build completed."
