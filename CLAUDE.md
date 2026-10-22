# Bekat — notes for Claude

Flutter app (Android / iOS / web): Namangan bus routes, RAPTOR transfer planner, 3D MapLibre map,
metro-style diagram. Public repo **github.com/ZedRubilan/bekat** (account ZedRubilan). See README.md
for structure and how the contest documents in `docs/` are generated.

Authors in every document: **Qodirov Ulug‘bek / Кодиров Улугбек** (author, +998 90 555 80 91) and
**Zamalitdinov Salim / Замалитдинов Салим** (co-author, salzamov@gmail.com), NamDTU, group 37-ATT-23 (r).

## ⚠️ Releasing — do not break the poster QR code
The QR code on the printed A3 posters and the deck's last slide points to
**https://zedrubilan.github.io/bekat/** (GitHub Pages, branch `gh-pages`). That page:
- on Android auto-downloads `https://github.com/ZedRubilan/bekat/releases/latest/download/Bekat.apk`,
- on iPhone/computers opens the web app at `https://zedrubilan.github.io/bekat/app/`.

So, for every new version:
1. **Use `tool/release.sh <version>`** (e.g. `tool/release.sh 1.0.1`). It bumps `pubspec.yaml`,
   runs analyze + tests, builds the APK, creates the GitHub release **marked latest** with the asset
   named **exactly `Bekat.apk`**, redeploys Pages, commits and pushes the version bump.
2. If doing it by hand instead, the rules are:
   - the release asset must be named `Bekat.apk` (not `app-release.apk`, no version in the name) and the
     release must be **latest** — otherwise `releases/latest/download/Bekat.apk` 404s and the QR breaks;
   - build with `flutter build apk --release --target-platform android-arm,android-arm64`
     (covers old 32-bit and new 64-bit phones, ~65 MB);
   - after any change to the app or to `site/index.html`, run **`tool/deploy_pages.sh`** — the web app is
     built with `--base-href /bekat/app/` and the landing page comes from `site/index.html`.
     Pushing to `main` alone does NOT update the website.
3. Never change the Pages URL, the repo name, or `site/index.html`'s download link — printed posters
   can't be updated. Check after releasing:
   `curl -sIL https://github.com/ZedRubilan/bekat/releases/latest/download/Bekat.apk | grep -i content-disposition`

APKs are debug-signed (no keystore yet) — fine for sideloading, not for Google Play.

## Data honesty
Only routes №1, №2, №3 and their end stops are confirmed. Intermediate stops and routes №5, №7, №9 are
demo data (`demo: true` in `assets/data/network.json`, shown as "namuna" / "пример"). Keep them
labelled as samples in the app, slides and posters; don't present them as real.
The Bekat 2.0 screens (stop display, in-bus screen, community routes, city dashboard) run on sample
data from `lib/data/demo_data.dart`; each screen carries a `DemoTag`. Keep that tag, and keep
"пример" on the deck/poster wherever they appear.

## Checks
`flutter analyze` and `flutter test` must pass. For visual checks of the web build use
`tool/shoot.py` (Playwright, see README). On the web, taps on overlays can leak to the map —
wrap new overlays in `PointerInterceptor(child: Guarded(child: …))` like the existing ones.
