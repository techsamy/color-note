# 11 — Run, Stop & Test (local machine)

Everything runs on this machine. Nothing needs an emulator: the app is previewed as Flutter web in a phone-sized
Brave window. Paths below are relative to the repo root (`/var/www/html/color-note`).

## 0. What runs where

| Service | How it runs | Address | Needed for |
|---|---|---|---|
| MySQL 8 | system service `mysql` (always on) | `127.0.0.1:3306`, DBs `huenote` + `huenote_test`, user `huenote` | API + API tests |
| API + website (Laravel) | `php artisan serve` (you start it) | <http://127.0.0.1:8000> | sign-in/sync in the app, website pages |
| App (Flutter web) | `flutter run` in Brave (you start it) | opens its own window | daily preview |

Apache and PHP-FPM are also installed as system services, but HueNote doesn't use them locally.

## 1. First time after `git pull`

```bash
cd app && flutter pub get && flutter gen-l10n && dart run build_runner build -d && cd ..
cd api && composer install && php artisan migrate && cd ..
```
Generated Dart files are git-ignored, so run `build_runner` again after pulling changes to models, providers or tables.

## 2. Start

**MySQL** is normally already running. Check it, and start it if needed:
```bash
systemctl status mysql --no-pager      # look for "active (running)"
sudo systemctl start mysql             # only if it is stopped
```

**API + website** (terminal 1, leave it open):
```bash
cd api && php artisan serve             # http://127.0.0.1:8000
```
Open in a browser:
- <http://127.0.0.1:8000/> — home
- `/privacy`, `/terms`, `/support`, `/delete-account`, `/reset-password`
- `/api/v1/health` — API health check

**App in a Brave phone window** (terminal 2), using either:
- VS Code → *Run and Debug* → **"HueNote (Brave mobile window)"** → ▶, or
- the terminal:
  ```bash
  cd app && CHROME_EXECUTABLE=$PWD/scripts/brave_mobile.sh flutter run -d chrome
  ```
While it runs, press `r` to hot reload, `R` to hot restart and `q` to quit. The app works without the API; the API
is needed only for *Settings → Account & sync*.

## 3. Stop

| What | How |
|---|---|
| App | `q` in its terminal (or Stop ■ in VS Code) |
| API + website | `Ctrl+C` in its terminal |
| Anything left running in the background | `pkill -f "artisan serve"`; `pkill -f "flutter run"` |
| MySQL (rarely needed) | `sudo systemctl stop mysql` · start again: `sudo systemctl start mysql` |

## 4. Test

### App (Flutter)
```bash
cd app
dart format --set-exit-if-changed . && flutter analyze   # style + lints, must be clean
flutter test                                             # unit + widget + flow + migration tests
```
The end-to-end sync test talks to the real API and is skipped unless you point it at a running API:
```bash
(cd api && php artisan serve --port=8001) &              # separate port, so your dev server keeps running
cd app && HUENOTE_E2E_API=http://127.0.0.1:8001/api/v1 flutter test test/e2e
pkill -f "artisan serve --port=8001"                     # stop it again
```
The test creates a throwaway account and deletes it at the end.

### API + website (Laravel)
```bash
cd api
composer lint      # Pint code style + Larastan static analysis
composer test      # Pest: API + website tests (uses the huenote_test database)
composer fix       # auto-fix code style if lint complains
```

### By hand in the browser
1. Start the API and the app (section 2).
2. Make a few notes, lock one (*Settings → Set master password*), search, archive, trash and restore.
3. Go to *Settings → Account & sync* → create an account → *Sync now*.
4. To test password reset: use *Forgot password?* in the app. Locally no email is sent; the link is written
   to `api/storage/logs/laravel.log` (because `MAIL_MAILER=log`). Open it to reach the reset page.
5. To test the website's account deletion, create an account in the app, then use
   <http://127.0.0.1:8000/delete-account>.

### Things only a real Android phone can test
Reminders, notifications, widgets, fingerprint unlock, share-to/from other apps, screenshot blocking on locked
notes, and real speed. See docs/08 §8 for USB/wireless debugging.

## 5. Regenerate the website screenshots

The home page shows real screenshots made from the app with demo notes (`app/tool/screenshots/main_demo.dart`).
After a UI change:
```bash
cd app && flutter build web -t tool/screenshots/main_demo.dart -o build/web_demo
cd build/web_demo && python3 -m http.server 8790
```
Open each URL below in a **fresh private window** sized to 412×892, and save a screenshot of each:
- `http://127.0.0.1:8790/?theme=light&view=grid` (home); tap *Groceries* for the editor shot
- `http://127.0.0.1:8790/?theme=dark&view=list` (dark); tap *Locked note* for the lock shot

Save them as 600 px wide WebP files in `api/public/images/screens/`, using the names `home-light`,
`editor-light`, `home-dark` and `locked-dark`.

## 6. Website settings (`api/.env`)

| Key | Meaning |
|---|---|
| `APP_NAME` | App name shown everywhere on the site (currently HueNote) |
| `APP_URL` / `FRONTEND_URL` | Base URL; password-reset emails link to `FRONTEND_URL/reset-password` |
| `HUENOTE_SUPPORT_EMAIL` | Contact address on every page |
| `HUENOTE_PUBLISHER` | Your name, shown as the developer on the legal pages (empty = hidden) |
| `HUENOTE_COUNTRY` | Governing law in the privacy policy and terms (India) |
| `HUENOTE_PLAY_STORE_URL` | When set, "Coming soon" becomes a real "Get it on Google Play" button |

After changing `.env`, run `php artisan config:clear`. If a page still shows the old text, also run
`php artisan view:clear`.
