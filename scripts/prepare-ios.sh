#!/usr/bin/env bash
# Run on the Mac with: bash scripts/prepare-ios.sh
set -euo pipefail

if [ "$(uname -s)" != "Darwin" ]; then
  echo "Acest script necesita macOS si Xcode. Nu compileaza iOS pe Windows." >&2
  exit 1
fi
for tool in flutter xcodebuild pod; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "Lipseste $tool. Vezi docs/INSTALARE-TELEFON.md." >&2
    exit 1
  fi
done

cd "$(dirname "$0")/.."
flutter pub get
flutter analyze
flutter test
flutter build ios --config-only --no-codesign --debug
(cd ios && pod install)

echo "Alege contul Apple si Team in Xcode > Runner > Signing & Capabilities."
echo "Pentru o instalare care se redeschide fara debugger, urmeaza pasii Release din ghid."
open ios/Runner.xcworkspace
