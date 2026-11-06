# 09 — Roadmap & Milestones

Estimates assume 1 full-time developer; adjust to your pace.

## Phase 0 — Foundation (week 1)
- [x] Package id: `com.samy.huenote` (locked forever after first Play Console upload — confirm before that)
- [ ] Final name, icon, domain (name can change anytime)
- [x] Scaffold `app/` (Flutter 3.47, flavours dev/prod, very_good_analysis, Riverpod, go_router, Drift)
- [x] Scaffold `api/` (Laravel 12 on PHP 8.2, Sanctum, Pest, Larastan L6, Pint, `/api/v1` + JSON error envelope)
- [x] CI pipelines (`.github/workflows/app.yml`, `api.yml`), git repo, ADRs 0001–0006
- [x] Theme + NotePalette (contrast-tested) + l10n wiring
- [x] Local MySQL user `huenote` + databases (`huenote`, `huenote_test`), migrations run
- [x] Daily dev preview: Flutter web in a Brave phone-sized window (`.vscode/launch.json`)
- [ ] Real-phone testing for Android-only features (USB debugging + Android command-line tools — no emulator needed) — before Phase 1 reminders/lock work
- [x] Push repo to GitHub (techsamy/color-note); CI green incl. Android dev APK build

## Phase 1 — Offline MVP (weeks 2–6)
- [x] Notes CRUD, text + checklist, auto-save, discard empty new notes (FR-N1..N3, N9)
- [x] Colours, colour labels, list/grid, sort, filter (FR-N4, L1..L3, L5)
- [x] FTS5 search, prefix + multi-word, injection-safe, locked notes excluded (FR-L4)
- [x] Archive, trash (+ auto-purge), pin, multi-select with undo (FR-N5..N7, L6)
- [x] Master password: per-note lock, AES-GCM + Argon2id, recovery key, change/reset, auto-relock (FR-S1, S3, S6)
- [x] Local encrypted backup/restore incl. locked notes from another device (FR-B1, manual)
- [x] Settings: theme, font size, default colour, checked-to-bottom, trash retention, auto-lock (FR-W2)
- [x] Verified in a real browser (headless Chrome via CDP): create note, search, reload persistence
- **Needs a real Android phone (step 9):**
  - [ ] Reminders + repeat + status-bar pin + reboot handling (FR-R1..R4)
  - [ ] Share in/out (FR-N8)
  - [ ] Biometric unlock (FR-S2), FLAG_SECURE on locked notes (FR-S4)
  - [ ] Scheduled auto-backup (FR-B1, background work)
- [ ] Internal testing release (needs Play Console account, icon, upload key, privacy policy — see Phase 2 "Small website")

## Phase 2 — Accounts & Sync (weeks 7–10) → v1.0 public
- [x] API: auth — email/password, Google ID-token sign-in (verifier + account linking), logout, password reset, per-device tokens, rate limits, app-version gate (FR-B2)
- [x] API: sync push/pull — per-note versions, conflicts, per-user change feed (sharing-ready fan-out), tombstones + purge, colour labels (FR-B3, B4)
- [x] API: master-key storage with optimistic concurrency (FR-S5), account deletion (FR-B6), device list/revoke
- [x] App: email account screen (sign in / create / forgot / sign out keep-or-remove / delete), sync status + Sync now (FR-B2, B5, B6, B10)
- [x] App: sync engine — dirty outbox, batched push, per-record conflicts → conflicted copy, paged pull, purge tombstones, colour labels; runs after edits (3 s), on start/resume, every 5 min (FR-B3, B4)
- [x] App: first sign-in merge, new-device restore, different-account re-id (FR-B8, B9)
- [x] App: master-key sync (adopt / upload / password changed elsewhere) + "different master password" resolution (FR-S5)
- [x] Local DB schema v2 (`purged`) with generated migration test
- [x] Verified end-to-end: Dart engine ↔ real Laravel + MySQL (`test/e2e`), and account creation + sync in a real browser
- [ ] App: Google sign-in button (needs OAuth client IDs; API side ready)
- [x] Export as .txt/.json zip (FR-B7) — Backup screen; locked/trashed notes excluded
- **Small website** (served by the Laravel API on the same domain as Blade pages, matching the app's colours, with feature tests) — docs/03 §4.4:
  - [x] Privacy policy `/privacy`, written from what the app actually does: no ads or tracking, locked notes encrypted end-to-end, what sync stores. **Required by Play.**
  - [x] Delete-account page `/delete-account`: request deletion without the app (sign in, confirm, revoke tokens). **Required by Play** for apps with accounts (FR-B6).
  - [x] Reset-password page `/reset-password`: the target of the reset email link (`frontend_url`)
  - [x] Home page (what the app is + real app screenshots + Play Store button), terms `/terms`, support/contact `/support`
  - [x] Verified in headless Chrome (desktop + phone width, light + dark, no horizontal overflow) and a real CSRF form post
- **Needs your input:**
  - [ ] Google Cloud OAuth client IDs (Android + web) → `GOOGLE_CLIENT_IDS` in api/.env
  - [ ] Email sending (SMTP / Mailgun etc.) for password-reset mails → `MAIL_*` in api/.env
  - [ ] Hosting for the API (this server vs VPS) + domain → staging + prod, backups, monitoring
  - [ ] Publisher name for the legal pages → `HUENOTE_PUBLISHER` (support email is configurable via `HUENOTE_SUPPORT_EMAIL`; currently your Gmail)
  - [ ] Final name + domain; Play Store link → `HUENOTE_PLAY_STORE_URL` once live
- [ ] Closed testing 14 days → production

## Phase 3 — v1.1 (weeks 11–14)
Calendar view · sticky-note widget · snooze · undo/redo · all-day reminders

## Phase 4 — Note sharing & differentiators (v1.2 – v1.3)
- [ ] v1.3 **Share notes between users** (FR-SH1..SH7): share API, invites, FCM push, shared badge, permissions
- [ ] Tags · Markdown rich text · image attachments · list widget · Google Drive backup · iOS release

## Phase 5 — v2 ideas
Web app · end-to-end encrypted sharing of locked notes · live co-editing · AI helpers (summarise, text→checklist; opt-in, privacy-first) · voice notes · handwriting

> Note: the sync model (per-user change feed + `note_members`) is built in Phase 2 specifically so Phase 4 sharing needs no sync redesign or data migration on devices.
