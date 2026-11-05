# CLAUDE.md — Project Rules

HueNote (working name): an offline-first, colour-coded notes app inspired by ColorNote.
**Flutter app (`app/`, Android first) + Laravel API (`api/`).** Completely free — no ads, no tracking.
Android package / applicationId: `com.samy.huenote` (can still change until the first Play Console upload; permanent after). App display name "HueNote" is a placeholder and can change anytime.

Read before working: `docs/02-product-requirements.md` (what), `docs/03-architecture.md` (how),
`docs/04-data-model.md`, `docs/05-api-spec.md`, `docs/10-coding-standards.md`.

## Golden rules
1. **Offline-first.** The local Drift DB is the UI's source of truth. Never block UI on network. Every feature must work without an account.
2. **Never lose user data.** Auto-save; soft-delete (tombstones); conflicts create a "conflicted copy" — never silently overwrite.
3. **Never log note content, passwords, tokens or keys** (app or server).
4. **Layering:** `presentation → domain ← data`. Domain is pure Dart (no Flutter/Drift/Dio imports). Features don't import other features' `data/` or `presentation/`.
5. **No hard-coded strings or colours** in widgets — use ARB (`AppLocalizations`) and `lib/app/theme/` tokens / `NotePalette`.
6. **Schema changes need migrations** — Drift: bump `schemaVersion` + migration step + migration test. Laravel: new migration file, never edit an existing one.
7. **API is additive within `/api/v1`.** Clients ignore unknown fields. Breaking change → `/v2` + ADR.
8. **Every server query is scoped to the authenticated user.** Controllers thin; logic in Services/Actions; validation in FormRequests; output via Resources.
9. **IDs are client-generated UUID v7.** Timestamps on notes are UTC epoch ms.
10. **Note colour enum values (0–8) are permanent** — never reorder or reuse.
11. Do not copy ColorNote's name, icon, artwork or text.
12. Reference requirement IDs (e.g. FR-N2) in commits/PRs. Conventional Commits.

## Commands
```bash
# app/
flutter pub get && flutter gen-l10n
dart run build_runner build -d          # after changing freezed/drift/riverpod files
dart format . && flutter analyze
flutter test
flutter run --flavor dev

# api/
composer install
composer fix                             # pint
composer lint                            # pint --test + larastan
composer test                            # Pest (MySQL db huenote_test)
php artisan migrate
```

## Stack notes
- Flutter 3.47 / Dart 3.13 — `dart fix` prefers `const new(...)` constructor syntax; follow the analyzer.
- Laravel 12 on PHP 8.2. API routes in `api/routes/api.php` under `v1`; errors rendered by `App\Support\ApiErrorRenderer`.
- Generated Dart code is gitignored — run codegen after pulling.
- Dev preview runs as **Flutter web in Brave** (`app/scripts/brave_mobile.sh`). Android-only features (notifications, alarms, widgets, biometrics, share intents) must sit behind a domain interface with a web no-op/fallback so the web preview keeps running; verify them on a real phone.
- `app/web/sqlite3.wasm` + `drift_worker.js` must match the resolved `sqlite3` / `drift` versions in pubspec.lock — re-download when upgrading drift.

## Testing notes (Flutter)
- Widget tests: use `test/helpers/pump_app.dart` (`pumpApp`, `settle`, `dbWrite`) — in-memory DB, fake secure store, fast KDF.
- Drift + fake async: read/write the DB from a test only inside `tester.runAsync`, ONE write per call (a live UI query re-runs between writes and deadlocks otherwise).
- Never `pumpAndSettle` while a spinner can be visible — use `settle()`.
- Real-browser smoke test: build web, serve `build/web`, drive headless Chrome over CDP (needs `--enable-unsafe-swiftshader`); headless Brave hangs in this environment.

## Before saying a task is done
- Format + analyze/lint clean, tests pass (run them; report failures honestly).
- New logic has tests; bug fixes have a regression test.
- Docs updated if a contract (API, schema, sync protocol) changed; significant decision → `docs/adr/`.
