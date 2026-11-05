# 02 — Product Requirements Document (PRD)

**Product (working name):** HueNote · **Platform v1:** Android (Flutter, iOS-ready code) · **Backend:** Laravel API · **Model:** Completely free, no ads

## 1. Goals
- G1: Feature parity with ColorNote's core (see `01-competitor-analysis.md`) in a modern UI.
- G2: Offline-first; optional account for backup + multi-device sync.
- G3: Architecture that makes adding new features cheap (feature modules, versioned API, migrations).

## 2. Non-goals (v1)
- iOS / web release (code stays portable, but not shipped).
- Rich text, attachments, collaboration/sharing between users, AI features.
- Monetisation of any kind (no ads, no IAP, no tracking SDKs).

## 3. Personas
| Persona | Need |
|---|---|
| Quick jotter | Open → type → done. Never loses a note. |
| List maker | Shopping / todo checklists, tick items fast. |
| Planner | Reminders, repeating tasks, calendar view. |
| Privacy-minded | Lock notes, encrypted backup, no tracking. |
| Multi-device | Same notes on phone + tablet. |

## 4. Functional requirements

IDs are referenced in code/PRs (e.g. `feat(notes): FR-N3 archive`).

### Notes (N)
| ID | Requirement | Release |
|---|---|---|
| FR-N1 | Create/edit/delete text notes; auto-save (debounced 500 ms) and on app pause | MVP |
| FR-N2 | Create/edit checklist notes; add/reorder/tick items; checked items move to bottom (setting) | MVP |
| FR-N3 | Convert text ⇄ checklist (each line ⇄ item) | MVP |
| FR-N4 | Assign one of 9 colours to a note; default colour configurable | MVP |
| FR-N5 | Archive / unarchive | MVP |
| FR-N6 | Trash (soft delete), restore, permanently delete, auto-purge after 30 days | MVP |
| FR-N7 | Pin note to top of list | MVP |
| FR-N8 | Share note as text; receive shared text as new note | MVP |
| FR-N9 | Duplicate note | MVP |

### List & search (L)
| ID | Requirement | Release |
|---|---|---|
| FR-L1 | List and grid views, toggle persisted | MVP |
| FR-L2 | Sort: modified, created, title, colour, reminder | MVP |
| FR-L3 | Filter by colour (multi-select) | MVP |
| FR-L4 | Full-text search (title + body + checklist items), results < 100 ms for 5 000 notes | MVP |
| FR-L5 | Rename colour labels | MVP |
| FR-L6 | Multi-select for bulk colour / archive / delete | MVP |

### Reminders (R)
| ID | Requirement | Release |
|---|---|---|
| FR-R1 | One-off reminder at date/time → notification opens the note | MVP |
| FR-R2 | Repeating reminder: daily, weekly (days), monthly, yearly | MVP |
| FR-R3 | Pin note to status bar (ongoing notification) | MVP |
| FR-R4 | Reminders survive reboot / app update / timezone change | MVP |
| FR-R5 | Calendar view (month) with notes by reminder/date | v1.1 |
| FR-R6 | Snooze from notification | v1.1 |

### Security (S)
| ID | Requirement | Release |
|---|---|---|
| FR-S1 | Lock individual notes with master password; content encrypted on device | MVP |
| FR-S2 | Biometric unlock as shortcut to master password | MVP |
| FR-S3 | Auto-relock after N minutes in background | MVP |
| FR-S4 | Hide locked-note content from widgets, notifications, recents screenshot (FLAG_SECURE on locked note) | MVP |
| FR-S5 | Same master password unlocks locked notes on every signed-in device (wrapped key synced, see arch §3.4) | v1.0 |
| FR-S6 | Change master password without re-encrypting notes; optional recovery key at setup | MVP (recovery key v1.0) |
| FR-S7 | Optional app lock (PIN / biometric to open app) | v1.1 |

### Backup & sync (B)
| ID | Requirement | Release |
|---|---|---|
| FR-B1 | Manual + scheduled local backup (encrypted file) and restore | MVP |
| FR-B2 | Sign up / sign in: email+password, Google | v1.0 |
| FR-B3 | Background bidirectional sync; works after offline edits | v1.0 |
| FR-B4 | Conflict handling: never overwrite silently — create "conflicted copy" | v1.0 |
| FR-B5 | Sync status indicator + "last synced" time | v1.0 |
| FR-B6 | Delete account + all server data (Play Store requirement) | v1.0 |
| FR-B7 | Export all notes as .txt / .json (zip) | v1.0 |
| FR-B8 | First sign-in on a device with offline notes merges them into the account (no duplicates, nothing lost) | v1.0 |
| FR-B9 | Sign in with the same account on a new device → all notes, colour labels, settings and reminders restored automatically | v1.0 |
| FR-B10 | Sign out asks: remove notes from device (default) or keep as offline notes | v1.0 |

### Sharing (SH) — Phase 4
| ID | Requirement | Release |
|---|---|---|
| FR-SH1 | Owner shares a specific note with another user by email, as editor or viewer | v1.3 |
| FR-SH2 | Recipient gets notification, accepts/declines; shared note appears in their list with "shared" badge | v1.3 |
| FR-SH3 | Edits sync to all members (push "tickle" for near-real-time); conflicts → conflicted copy | v1.3 |
| FR-SH4 | Colour, pin, archive, reminder stay personal per member | v1.3 |
| FR-SH5 | Owner can change permission / revoke; member can leave | v1.3 |
| FR-SH6 | Invite by email for users without an account (activates on sign-up) | v1.3 |
| FR-SH7 | Locked notes cannot be shared (E2E-encrypted sharing is a v2 item) | v1.3 |

### Widgets & settings (W)
| ID | Requirement | Release |
|---|---|---|
| FR-W1 | Single-note sticky widget, note colour as background | v1.1 |
| FR-W2 | Settings: theme (system/light/dark), font size, default colour, sort, checklist behaviour, trash retention | MVP |

## 5. Non-functional requirements
| ID | Requirement |
|---|---|
| NFR-1 | Cold start ≤ 1.5 s on mid-range device (e.g. 4 GB RAM, 2021 SoC) |
| NFR-2 | Editor input latency: no dropped frames while typing (60 fps) |
| NFR-3 | APK (per-ABI) ≤ 20 MB |
| NFR-4 | Zero data loss: crash during typing loses ≤ 1 s of text |
| NFR-5 | Accessibility: TalkBack labels, 48 dp touch targets, contrast ≥ 4.5:1 on every note colour |
| NFR-6 | Localisation-ready (all strings in ARB), RTL-safe layouts; v1 ships English (+ Hindi optional) |
| NFR-7 | Privacy: no analytics/ads SDKs; crash reporting opt-in only |
| NFR-8 | Min Android: API 24 (7.0); target: latest required by Play |
| NFR-9 | API p95 latency < 300 ms for sync calls; supports 10k users on one VPS |

## 6. Release plan
| Release | Scope | Exit criteria |
|---|---|---|
| **MVP (offline)** | N*, L*, R1–R4, S*, B1, W2 | Internal testing track, 0 P0 bugs, all MVP tests green |
| **v1.0** | + Laravel API, accounts, sync, export, account deletion | Closed testing ≥ 14 days with ≥ 12 testers (Play requirement for new personal accounts), public launch |
| **v1.1** | Calendar view, sticky widget, snooze, undo/redo, all-day reminders | |
| **v1.2+** | Tags, rich text (Markdown), images, list widget, iOS build | |
| **v2** | Web app, AI helpers (opt-in), shared notes | |

## 7. Success metrics (measured without tracking SDKs)
- Play Console vitals: crash-free users ≥ 99.5 %, ANR rate < 0.2 %.
- Play rating ≥ 4.5.
- Server: sync error rate < 0.5 % of requests.

## 8. Open questions
- Final app name, icon and brand colours.
- Will Google Drive backup be offered in addition to our own server? (Proposed: v1.2.)
- Hosting target for Laravel API (this server vs. a VPS/cloud).
