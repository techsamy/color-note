# HueNote — Flutter app

Package: `com.samy.huenote` (dev flavour installs as `com.samy.huenote.dev`).
Rules: see `../CLAUDE.md` and `../docs/`.

```bash
flutter pub get
flutter gen-l10n
dart run build_runner build -d          # Drift / Riverpod / freezed codegen
CHROME_EXECUTABLE=$PWD/scripts/brave_mobile.sh flutter run -d chrome   # Brave phone window
flutter run --flavor dev                # real Android phone (USB debugging)
flutter analyze && flutter test
```

Override the API URL: `--dart-define=API_BASE_URL=http://192.168.1.10:8000/api/v1`

Web DB files (`web/sqlite3.wasm`, `web/drift_worker.js`) are pinned to sqlite3 3.5.2 / drift 2.35.3 — download
matching versions from the sqlite3.dart and drift GitHub releases when upgrading.
