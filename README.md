# Bekat 🚌 — Namangan avtobuslari uchun aqlli marshrut xaritasi

## 📲 [Ilovani yuklab olish / Скачать приложение](https://zedrubilan.github.io/bekat/)

| | |
|---|---|
| **Android** | [⬇️ Bekat.apk — yuklab olish](https://github.com/ZedRubilan/bekat/releases/latest/download/Bekat.apk) |
| **iPhone / kompyuter** | [🌐 Brauzerda ochish](https://zedrubilan.github.io/bekat/app/) |

O‘rnatish: faylni oching → telefon so‘rasa, “noma’lum manbalardan o‘rnatish”ga ruxsat bering → “O‘rnatish”.

---

**Bekat** ("bus stop" in Uzbek) shows how to get anywhere in Namangan by city bus:
pick a place on the 3D map or search for it, and the app shows which bus to take, where to
change, how long to walk and when the bus arrives. If no bus goes there, it shows the
closest you can get. Authors: **Qodirov Ulug‘bek** and **Zamalitdinov Salim** (NamDTU,
group 37-ATT-23 (r)), for the "Eng yaxshi kreativ g‘oya" 2026 contest.

## Features (working prototype)
- **3D live map**: MapLibre + OpenFreeMap/OpenStreetMap tiles, white extruded buildings,
  coloured route lines, animated buses with route badges.
- **Trip planner with transfers**: RAPTOR (Delling et al., 2012), runs on the phone, up to
  2 transfers, walking between nearby stops, plus a "closest reachable" mode.
- **Metro-style network diagram**: hand-laid octilinear map of all lines, with live buses
  and tap-a-stop arrivals.
- **Trip mode**: stop strip, stops left, time left, bus ETA, where to get off or change.
- **Search** in Latin and Cyrillic (`chorsu` = `Чорсу`), online Nominatim fallback.
- Uzbek / Russian / English, a large-text mode, and a ×10 demo clock for presentations.

## Bekat 2.0 — concept screens (sample data)
Ideas for the next stages, already clickable in the prototype ("Kelajak / Будущее" button on the
map, or Settings → Bekat 2.0). Every number on these screens is a **sample** and is labelled so.
- **Stop display** — next buses, where each one goes (mini-map with live buses), community routes
  through the stop; at the bus station also intercity departures (Chust, Kosonsoy, Pop…).
- **In-bus screen** — next stop in big letters, transfers, the whole line with the bus on it.
- **Community routes** — damas / marshrutka / shared taxi routes added and confirmed by riders
  (saved on the phone; moderation is a later stage).
- **City dashboard** — heatmap of searches and of places no bus reaches, top requests, hourly
  demand, recommendations. Hotspot locations and distances are real (OSM), counts are samples;
  the "on this device" card counts real searches made on the phone.

The displays are the same web build in kiosk mode, so a cheap screen with a browser is enough:
`/app/?board=chorsu`, `?board=avtovokzal`, `?bus=3`, `?demand`, `?community`, `?future`.

## What is real and what is a sample
| Data | Status |
|---|---|
| Routes №1 Otchopar–Taxtako‘prik, №2 Otchopar–Chorsu, №3 Yuksalish–Chorsu | Numbers and end stops **confirmed** (Mintrans, press 2026) |
| Intermediate stops of №1–3 | Real landmarks, **illustrative order**, until the field survey |
| Routes №5, №7, №9 | **Demo** (`demo: true`), shown as "namuna" in the app |
| Stop/POI coordinates | Real (OpenStreetMap, Nominatim) |
| Line shapes | Shortest path on Namangan's main roads (OSM) |
| Bus positions / ETAs | Simulated from headway (18 km/h), not live GPS |
| Bekat 2.0 screens (intercity timetable, community routes, demand numbers) | **Sample** data (`lib/data/demo_data.dart`) |

Project stage 1 replaces the samples with GPS-surveyed routes in GTFS format.

## Run
```bash
flutter pub get
flutter run                      # Android / iOS device
flutter run -d chrome            # web
flutter test                     # 7 planner/search/schedule tests
flutter build web --release      # build/web
flutter build apk --release      # build/app/outputs/flutter-apk/app-release.apk (debug-signed)
```
Web-only URL switches for renders: `?clean` hides overlays; `?cam=lat,lon,zoom,tilt,bearing` fixes the camera.

## Structure
```
lib/
  main.dart                 app + animated splash
  core/  app_state.dart     state, clock (demo ×10), GPS (falls back to NamDTU outside Namangan)
         i18n.dart          uz/ru/en strings     theme.dart  design tokens
  data/  network.dart       stops, routes, polylines
         schedule.dart      headway timetable → bus positions & arrivals
         planner.dart       RAPTOR journeys      search.dart  Latin/Cyrillic search
  data/  demo_data.dart     sample data for the Bekat 2.0 screens
  ui/    home_screen.dart   search pill, nearby card, options, trip mode
         future_screen.dart Bekat 2.0 hub      stop_board.dart  bus_screen.dart
         community_screen.dart  demand_screen.dart  mini_map.dart (offline schematic map)
         map_view.dart      MapLibre map, buses, trip layer, camera tween
         map_style.dart     light 3D style      scheme_screen.dart  metro diagram
         search_screen.dart settings_sheet.dart  widgets.dart (badges, iso bus, sprites)
data/build_network.py       builds assets/data/network.json (OSM + road graph)
tool/shoot.py               headless screenshots of the web build
docs/                       contest documents (below)
```

## Contest documents (`docs/`)
| File | What |
|---|---|
| `Eng_yaxshi_kreativ_goya_Bekat_Qodirov_Ulugbek.docx` | Application form (template filled in), built by `build_ariza.py` |
| `Bekat_Taqdimot_UZ.pptx`, `Bekat_Prezentatsiya_RU.pptx` | 14-slide decks, built by `deck/build_deck.js` |
| `poster/Bekat_poster_A3_UZ.pdf/.png`, `…_RU…` | A3 posters, built by `poster/render_poster.py` |
| `Bekat StudEXPO-2026.pptx/.pdf` | 7-slide StudEXPO deck (RU), built by `studexpo/bekat.js` |
| `shots/`, `assets/` | Real app screenshots and mockups (`make_assets.py`) |

Regenerate after app changes:
```bash
flutter build web --release && (python3 -m http.server 8766 -d build/web &)
python3 tool/shoot.py docs/shots/uz "wait:1300;shot:01_splash;wait:10500;shot:02_home;click:340,553;wait:2800;shot:03_scheme;click:36,32;wait:1500;click:170,40;wait:1200;type:chorsu;wait:1000;shot:04_search;click:200,118;wait:4200;shot:05_plan;click:310,680;wait:5000;shot:06_trip" uz
#   (same with docs/shots/ru, "type:чорсу" and last argument ru)
W=1500 H=1150 python3 tool/shoot.py docs/shots/uz "wait:11000;click:1428,823;wait:3200;shot:scheme_wide" uz
W=1600 H=1000 Q="?clean&cam=41.0045,71.6745,15.2,62,-28" python3 tool/shoot.py docs/shots/uz "wait:17000;shot:map_center" uz
# Bekat 2.0 screens (both languages; last argument uz / ru)
for q in board=chorsu:f_board board=avtovokzal:f_intercity bus=3:f_bus; do W=1600 H=900 DPR=1.5 Q="?${q%%:*}" python3 tool/shoot.py docs/shots/uz "wait:4000;shot:${q##*:}" uz; done
W=1600 H=900 DPR=1.5 Q="?demand" python3 tool/shoot.py docs/shots/uz "wait:10000;shot:f_demand" uz
W=1200 H=675 DPR=2 Q="?community" python3 tool/shoot.py docs/shots/uz "wait:3000;shot:f_community" uz
W=1200 H=675 DPR=2 Q="?future" python3 tool/shoot.py docs/shots/uz "wait:3000;shot:f_future" uz
python3 docs/make_assets.py
(cd docs/deck && npm install && node build_deck.js)
(cd docs/studexpo && npm install && node bekat.js)   # then: soffice --headless --convert-to pdf
python3 docs/poster/render_poster.py
python3 docs/build_ariza.py
```

Map data © OpenStreetMap contributors (ODbL), tiles by OpenFreeMap. Font: Inter (OFL).
