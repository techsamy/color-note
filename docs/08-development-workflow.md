# 08 — Development Workflow, Testing & Release

## 1. Repository layout (monorepo)
```
color-note/
├─ CLAUDE.md            # rules for AI assistants (and humans)
├─ README.md
├─ docs/                # these documents + adr/
├─ app/                 # Flutter app
├─ api/                 # Laravel API
└─ .github/workflows/   # app.yml, api.yml
```

## 2. Git
- Branches: `main` (always releasable) ← `feature/<short-name>`, `fix/<short-name>`.
- **Conventional Commits**: `feat(notes): add checklist reorder (FR-N2)`, `fix(sync): ...`, `chore`, `docs`, `refactor`, `test`.
- PRs: small (< 400 lines diff preferred), template checklist (see §6), at least CI green before merge; squash-merge.
- Tags: `app-v1.0.0`, `api-v1.0.0`.

## 3. Versioning
- App: `pubspec.yaml` `version: MAJOR.MINOR.PATCH+BUILD`; BUILD strictly increasing (Play versionCode).
- API: URL-versioned (`/v1`), plus semantic tags for deploys.
- Local DB: Drift `schemaVersion` integer, one migration step per version.

## 4. Testing strategy
| Layer | What | Tool | Target |
|---|---|---|---|
| Domain (Dart) | Use cases, recurrence rules, checklist conversion, conflict logic | flutter_test | ~100 % of domain |
| Data (Dart) | DAOs with in-memory Drift, mappers, repository impl with mocked API | flutter_test + mocktail | key paths |
| Migrations | Each Drift schema version upgrade | drift_dev schema tests | every version |
| Widgets | Editor, list, reminder sheet | widget tests + golden tests (light/dark) | main screens |
| Integration | Create → edit → search → delete → restore; lock/unlock; backup/restore | integration_test on emulator | MVP flows |
| API | Every endpoint: happy path, validation, auth, ownership, sync conflict | Pest Feature tests | 100 % endpoints |
| Sync E2E | Two simulated devices editing same note | Pest + Dart test harness | conflict cases |

Rule: **every bug fix comes with a test that fails before the fix.**

## 5. CI (GitHub Actions)
**app.yml** (paths: `app/**`): `flutter pub get` → `dart format --set-exit-if-changed` → `flutter analyze` → `flutter test --coverage` → `flutter build appbundle --flavor prod` (on tag; signs with secrets).
**api.yml** (paths: `api/**`): `composer install` → `pint --test` → `larastan` → `pest` (MySQL + Redis service containers) → deploy on tag.

## 6. Definition of Done
- [ ] Requirement ID(s) referenced; acceptance criteria met
- [ ] Works offline (app) / scoped to user (api)
- [ ] Tests added/updated, CI green
- [ ] No hard-coded strings (ARB) or colours (theme)
- [ ] Dark mode + large font checked
- [ ] Migration added if schema changed (+ migration test)
- [ ] Docs updated (API spec / data model / ADR) if contract changed
- [ ] No secrets, no logging of note content

## 7. Release (Android)
1. Bump version → tag `app-vX.Y.Z` → CI builds signed AAB (Play App Signing enabled).
2. Upload to **Internal testing** → smoke test.
3. **Closed testing** (new personal developer accounts: ≥ 12 testers for ≥ 14 days before production access).
4. Production with **staged rollout** 10 % → 50 % → 100 %, watching Android vitals.
5. Store listing needs: original icon, feature graphic, screenshots, short/long description, privacy policy URL, data-safety form, content rating questionnaire, account-deletion URL.

## 8. Local setup
Requirements: Flutter 3.47.x (Dart 3.13), Brave/Chrome, PHP 8.2+, Composer, MySQL 8.
Android SDK command-line tools + Java 17 only when testing on a real phone or building the APK/AAB.

### Daily preview: Brave mobile window (no emulator)
- VS Code → Run and Debug → **"HueNote (Brave mobile window)"** (or task *App: run in Brave*).
- Terminal: `cd app && CHROME_EXECUTABLE=$PWD/scripts/brave_mobile.sh flutter run -d chrome`
- Opens a 412×892 Brave app window; hot reload works (`r`).
- Web preview uses `http://127.0.0.1:8000/api/v1` → start the API with `php artisan serve`.

**Web preview cannot test** (needs a real Android phone): reminders/exact alarms, status-bar pin, notifications,
home widgets, biometrics, Keystore secure storage, share intents, back-button behaviour, real performance.
Real phone without emulator: enable *Developer options → USB/Wireless debugging*, install Android command-line
tools (`sdkmanager "platform-tools" "platforms;android-36" "build-tools;36.0.0"`), then `flutter run --flavor dev`.


```bash
# App
cd app
flutter pub get && flutter gen-l10n && dart run build_runner build -d
flutter run --flavor dev
flutter analyze && flutter test

# API
cd api
composer install
cp .env.example .env && php artisan key:generate   # fill DB_USERNAME / DB_PASSWORD
php artisan migrate && php artisan serve
composer lint && composer test
```
Generated Dart files (`*.g.dart`, `*.freezed.dart`, `lib/l10n/gen/`) are not committed — CI regenerates them.
Note: Laravel 12 is used because the server runs PHP 8.2; upgrading PHP to 8.3+ unlocks the next Laravel major.
