# 01 — Competitor Analysis: ColorNote

> Reference app: **ColorNote® Notepad Notes** by Social & Mobile Inc.
> Play Store ID: `com.socialnmobile.dictapps.notepad.color.note`
> Note: the Play Store page could not be fetched automatically (JS-rendered). Store metrics below are
> approximate public knowledge — re-verify rating / installs manually before quoting them anywhere.

## 1. Snapshot

| Item | Value (approx.) |
|---|---|
| Category | Productivity |
| Installs | 100M+ |
| Rating | ~4.6★ with millions of reviews |
| Price | Free |
| Positioning | Simple, fast, colour-coded notepad with checklists, reminders and sync |
| Age of product | Since ~2009 — UI looks dated, which is our main opening |

## 2. Feature inventory (what we must match for parity)

### 2.1 Note types
| Feature | Details | Our priority |
|---|---|---|
| Text note | Plain-text, lined-paper style editor | **MVP** |
| Checklist note | Items with tick/untick; checked items struck through and moved down | **MVP** |

### 2.2 Organisation
| Feature | Details | Priority |
|---|---|---|
| Colour coding | ~9 colours (red, orange, yellow, green, blue, purple, black, grey, white); colour is the main "folder" concept | **MVP** |
| Colour labels | User can rename what each colour means (e.g. Red = "Work") | **MVP** |
| Sort | By modified time, created time, alphabetical, colour, reminder time | **MVP** |
| View modes | List, grid, details | **MVP** (list + grid) |
| Search | Full-text search over title + body | **MVP** |
| Archive | Hide notes without deleting | **MVP** |
| Trash / recycle bin | Soft delete, restore | **MVP** |
| Calendar view | Notes shown on calendar by date / reminder; create note for a date | v1.1 |

### 2.3 Reminders & visibility
| Feature | Details | Priority |
|---|---|---|
| Time alarm reminder | One-off date/time | **MVP** |
| Repeating reminder | Daily / weekly / monthly / yearly | **MVP** |
| All-day reminder | Shows in calendar, no alarm sound | v1.1 |
| Pin to status bar | Persistent notification showing the note | **MVP** |
| Home-screen sticky-note widget | Shows a note in its colour on the launcher | v1.1 |
| Note-list widget | Widget listing notes | v1.2 |

### 2.4 Security & data
| Feature | Details | Priority |
|---|---|---|
| App/master password lock | Locks notes behind a password | **MVP** (per-note lock) |
| Online backup & sync | Account (email / Google), AES-encrypted backup, multi-device sync | v1.0 (Laravel API) |
| Local backup | Encrypted backup to device storage, auto-backup | **MVP** |
| Share note | Android share sheet (text) | **MVP** |
| Receive shared text | "Share to app" creates a note | **MVP** |

### 2.5 Misc
| Feature | Priority |
|---|---|
| Dark theme | **MVP** |
| Font size setting | **MVP** |
| Auto-save while typing | **MVP** |
| Undo/redo in editor | v1.1 |
| Word count / note info | v1.1 |

## 3. Strengths (keep these)
1. **Speed** — opens instantly, zero friction to write.
2. **Simplicity** — two note types, colours instead of folders.
3. **Offline-first** — fully usable with no account.
4. **Light footprint** — small APK, low RAM.
5. **Trust** — encrypted backup, long track record.

## 4. Weaknesses (our opportunities)
| Weakness in ColorNote | Our answer |
|---|---|
| Dated, pre-Material UI | Modern Material 3 UI, dynamic colour, smooth animations |
| Plain text only | Phase 2: light rich text (bold, lists, links) — Markdown-backed |
| No images / attachments | Phase 2: image + audio attachments |
| No tags beyond colour | Phase 2: tags/labels in addition to colour |
| Sync is opaque, occasional conflict complaints | Transparent sync status, conflict copies, sync history |
| No web access | Phase 3: web app (Flutter web or separate) |
| Limited widget styling | Modern resizable widgets (Material You) |
| No AI / smart features | Phase 3: summarise, auto-checklist, smart reminders (optional, privacy-first) |
| Password lock is basic | Biometric unlock + proper client-side encryption of locked notes |

## 5. Differentiation strategy (one-liner)
> **"ColorNote's simplicity, with a modern UI, real privacy and features it never shipped."**
> Stay free and ad-free; never make the core flow slower than ColorNote's.

## 6. Non-negotiables derived from the analysis
1. Cold start to an editable note in **< 1.5 s** on a mid-range Android.
2. Every feature works **offline**; account is optional.
3. **No data loss ever** — auto-save, soft-delete, conflict copies, backups.
4. Colour is a first-class concept everywhere (list, editor, widget, calendar).
5. Do **not** copy ColorNote's name, icon, artwork, or text — build original branding.
