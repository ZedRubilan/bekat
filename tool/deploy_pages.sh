#!/usr/bin/env bash
# Publish the download page + web app to GitHub Pages (branch gh-pages).
#   https://zedrubilan.github.io/bekat/      landing page (QR on the poster points here)
#   https://zedrubilan.github.io/bekat/app/  the Flutter web app
set -euo pipefail
cd "$(dirname "$0")/.."
REMOTE=$(git remote get-url origin)
flutter build web --release --base-href /bekat/app/ --output build/web_pages
OUT=build/site
rm -rf "$OUT" && mkdir -p "$OUT"
cp site/index.html "$OUT/"
cp docs/assets/bus.png "$OUT/bus.png"
cp web/icons/Icon-192.png "$OUT/icon.png"
cp -r build/web_pages "$OUT/app"
touch "$OUT/.nojekyll"
cd "$OUT"
git init -q -b gh-pages
git add -A
git -c user.name="$(git -C ../.. config user.name)" -c user.email="$(git -C ../.. config user.email)" \
  commit -q -m "Publish Bekat download page and web app"
git push -f "$REMOTE" gh-pages
echo "published"
