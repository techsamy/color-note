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
- [ ] Internal testing release (needs Play Console account, icon, upload key, privacy policy)

## Phase 2 — Accounts & Sync (weeks 7–10) → v1.0 public
- [ ] Auth API + app screens (FR-B2)
- [ ] Sync API + engine + conflict copies (FR-B3..B5)
- [ ] Export, account deletion, privacy policy page (FR-B6, B7)
- [ ] Server deploy (staging + prod), backups, monitoring
- [ ] Closed testing 14 days → production

## Phase 3 — v1.1 (weeks 11–14)
Calendar view · sticky-note widget · snooze · undo/redo · all-day reminders

## Phase 4 — Note sharing & differentiators (v1.2 – v1.3)
- [ ] v1.3 **Share notes between users** (FR-SH1..SH7): share API, invites, FCM push, shared badge, permissions
- [ ] Tags · Markdown rich text · image attachments · list widget · Google Drive backup · iOS release

## Phase 5 — v2 ideas
Web app · end-to-end encrypted sharing of locked notes · live co-editing · AI helpers (summarise, text→checklist; opt-in, privacy-first) · voice notes · handwriting

> Note: the sync model (per-user change feed + `note_members`) is built in Phase 2 specifically so Phase 4 sharing needs no sync redesign or data migration on devices.
