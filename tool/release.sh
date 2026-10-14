#!/usr/bin/env bash
# One command to ship a new Bekat version without breaking the poster QR code.
#   tool/release.sh 1.0.1        (version name; build number is bumped automatically)
# It: bumps pubspec version → tests → builds the APK → publishes GitHub release
# vX.Y.Z (marked latest) with the asset named exactly Bekat.apk → redeploys GitHub Pages
# (landing page + web app) → commits and pushes the version bump.
set -euo pipefail
cd "$(dirname "$0")/.."
NAME="${1:?usage: tool/release.sh <version, e.g. 1.0.1>}"
REPO=ZedRubilan/bekat
OLD=$(grep '^version:' pubspec.yaml | sed 's/version: *//')
CODE=$(( ${OLD#*+} + 1 ))
sed -i "s/^version: .*/version: ${NAME}+${CODE}/" pubspec.yaml
echo "version ${OLD} -> ${NAME}+${CODE}"

flutter analyze
flutter test
flutter build apk --release --target-platform android-arm,android-arm64
mkdir -p build/release
cp build/app/outputs/flutter-apk/app-release.apk build/release/Bekat.apk   # name must stay Bekat.apk

gh release create "v${NAME}" build/release/Bekat.apk --repo "$REPO" --latest \
  --title "Bekat ${NAME}" \
  --notes "📲 Android: download Bekat.apk below (or just open https://zedrubilan.github.io/bekat/).
🌐 iPhone / computer: https://zedrubilan.github.io/bekat/app/"

./tool/deploy_pages.sh

git add pubspec.yaml
git commit -m "Release ${NAME}"
git push
# sanity check: the QR target must still resolve to the new APK
curl -sIL "https://github.com/${REPO}/releases/latest/download/Bekat.apk" | grep -i "content-disposition"
echo "released ${NAME}"
